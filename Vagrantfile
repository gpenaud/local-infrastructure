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
