# LOCAL INFRASTRUCTURES

a special guide to build local and powerful infrastructures based on vagrant, lxc and dnsmasq.
it works especially good on laptops, and can without problem be used through wlan connections


## lxc

step 1:
  install lxc package

step 2:
  stop and disable lxc-net
  ```
  sudo systemctl stop lxc-net
  sudo systemctl disable lxc-net
  ```


## vagrant

step 3:
  install vagrant package

step 4:
  install vagrant-lxc plugin
  ```
  sudo vagrant plugin install vagrant-lxc
  ```

step 5:
  create a Vagrantfile with the following content

  ```
  #! /usr/bin/ruby
  require "yaml"

  IMAGE    = "fgrehm/trusty64-lxc"
  NODES    = [
    "node-test-01",
    "node-test-02",
  ]

  Vagrant.configure(2) do |config|
    config.vm.box = IMAGE

    NODES.each do |node|
      config.vm.define node do |instance|
        instance.vm.hostname = node
        instance.vm.provider :lxc do |lxc|
          lxc.container_name = :machine
          lxc.customize "net.0.link", "lxc-bridge"
        end
      end
    end
  end
  ```


## networking

the tricky part ; we will create dead interfaces whose role will just be to forward packets
on our selected "real" wlan interface (wlp58s0 in this example) ; each of those interface
will be bound to a dnsmasq instance ; this dnsmasq will manage dns and dhcp for all containers
linked to this "dead interface" by their veth.

step 6:
  create interfaces in /etc/network/interfaces (choose ip/netmask range of your own)

  ```
  auto lxc-bridge
  iface lxc-bridge inet static
    bridge_ports none
    bridge_fd 0
    bridge_maxwait 0
    address 10.101.0.1
    netmask 255.255.255.0
    down iptables -t nat -D POSTROUTING -s 10.101.0.0/24 -o wlp58s0 -j MASQUERADE
    up   iptables -t nat -A POSTROUTING -s 10.101.0.0/24 -o wlp58s0 -j MASQUERADE
    down iptables -t mangle -D POSTROUTING -p udp --dport bootpc -s 10.101.0.0/24 -j CHECKSUM --checksum-fill || true
    up   iptables -t mangle -A POSTROUTING -p udp --dport bootpc -s 10.101.0.0/24 -j CHECKSUM --checksum-fill || true
  ```

  nat rules are here to redirect all traffic on real interfaces, connected to the web
  mangle rules ... needed but i do not remember why ; very sorry ^^

step 7:
  enable ip forwarding
  ```
  echo 1 > /proc/sys/net/ipv4/ip_forward
  ```

step 8 (optional):
  if you're using NetworkManager, don't forget to enable ifupdown management in
  /etc/NetworkManager/NetworkManager.conf

  ```
  [main]
  plugins=ifupdown,keyfile
  dns=none

  [ifupdown]
  managed=true
  ```

  then restart NetworkManager service


## dnsmasq

with this network configuration, we need to setup N dnsmasq instances, one by
network ; first, we need to generate a "proxy" dnsmasq instance, wich will redirect
dns queries from localhost to inner bridged networks and google dns  

step 9:
