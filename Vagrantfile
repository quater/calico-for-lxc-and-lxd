# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.synced_folder ".", "/home/vagrant/shared_folder"
  config.vm.provision "shell", inline: <<-SHELL
    set -e -x -u

    apt-get update -y || (sleep 40 && apt-get update -y)
    apt-get install -y git build-essential lxc etcd aufs-tools conntrack
    snap install go --classic
    snap install docker
    groupadd docker
    usermod -aG docker vagrant

  SHELL
end
