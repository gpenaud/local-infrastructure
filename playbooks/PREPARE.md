apt install bridge-utils


s bcrctl show
k8s-bridge

---

cat /etc/lxc/default.conf
lxc.network.type  = veth
lxc.network.flags = up

---

cat /etc/lxc/lxc.conf
lxc.lxcpath = /home/gpenaud/virtual/lxc


---

cat /etc/network/interfaces.d/k8s-bridge
auto k8s-bridge
iface k8s-bridge inet static
  bridge_ports none
  bridge_fd 0
  bridge_maxwait 0
  address 10.242.0.1
  netmask 255.255.255.0
  up iptables -t nat -A POSTROUTING -s 10.242.0.0/24 -o wlp59s0 -j  MASQUERADE
  up iptables -t mangle -A POSTROUTING -p udp --dport bootpc -s 10.242.0.0/24 -j CHECKSUM --checksum-fill || true

cat /etc/resolv.conf
search lxc.lan k8s.lan express.local
nameserver 127.0.0.1

---

cat /etc/dnsmasq.d/proxy.conf

interface=lo
bind-dynamic

cache-size=1000000

server=/lxc.lan/10.239.0.1
server=/local.lan/10.240.0.1
server=/express.local/10.241.0.1
server=/k8s.local/10.242.0.1
server=/#/8.8.8.8

---

cat /etc/dnsmasq.d/k8s.conf

interface=k8s-bridge
bind-dynamic
no-hosts

domain=k8s.lan

dhcp-range=10.242.0.2,10.242.0.254,12h
dhcp-option=1,255.255.255.0
dhcp-option=3,10.242.0.1

dhcp-host=00:12:41:77:f9:51,10.242.0.11
dhcp-host=00:12:41:77:f9:52,10.242.0.12
dhcp-host=00:12:41:77:f9:53,10.242.0.13
dhcp-host=00:12:41:77:f9:54,10.242.0.14
dhcp-host=00:12:41:77:f9:55,10.242.0.15

cname=apiserver.k8s.lan,master1

server=/k8s.lan/10.242.0.1
server=/#/8.8.8.8

---

sctl cat dnsmasq@k8s
# /lib/systemd/system/dnsmasq@.service
[Unit]
Description=DHCP and DNS cache server bound on specified interface
After=network.target

[Service]
ExecStart=/usr/sbin/dnsmasq -k --conf-file=/etc/dnsmasq.d/%i.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
