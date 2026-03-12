#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

if [ -d "/opt/cni/bin/" ] && [ -f "/etc/cni/net.d/10-mynet.conf" ]; then
    echo "The CNI plugins and the configuration are installed."
else
    mkdir -p /opt/cni/bin /etc/cni/net.d
    cd ../Downloads
    wget https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
    tar -xzvf cni-plugins-linux-amd64-v1.4.0.tgz -C /opt/cni/bin
    cp ../configs/10-mynet.conf /etc/cni/net.d
fi