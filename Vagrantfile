# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "4096"]
    vb.customize ["modifyvm", :id, "--cpus",   "4"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -e
    echo deb http://http.debian.net/debian jessie-backports main >> /etc/apt/sources.list.d/debian-backports.list
    apt-get update
    apt-get install -y rsync subversion openjdk-8-jre python-matplotlib python-beautifulsoup python-numpy python-gdal

    # download and install phyghtmap
    tmp_file=$(mktemp)
    wget -q --progress=bar:force --show-progress http://katze.tfiu.de/projects/phyghtmap/phyghtmap_1.74-1_all.deb -O $tmp_file
    dpkg -i $tmp_file
  SHELL
end
