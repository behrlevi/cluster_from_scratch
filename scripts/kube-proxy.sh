#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

if which kube-proxy >/dev/null 2>&1; then
    echo "The Kube Proxy is installed."
else
    cd ../Downloads
    wget https://dl.k8s.io/v1.26.0/bin/linux/amd64/kube-proxy
    cp kube-proxy /usr/local/bin/
    chmod +x /usr/local/bin/kube-proxy
    # The proxy uses conntrack to apply firewall rules
    apt install -y conntrack
    # Create the expected directory and the empty config file
    mkdir -p /var/lib/kube-proxy
    touch /var/lib/kube-proxy/kube-proxy.kubeconfig
fi

# Donwload and install the binary

# wget https://dl.k8s.io/v1.26.0/bin/linux/amd64/kube-proxy
# cp kube-proxy /usr/local/bin/
# chmod +x /usr/local/bin/kube-proxy
# The proxy uses conntrack to apply firewall rules
# apt install -y conntrack

/usr/local/bin/kube-proxy \
  --config=../configs/kube-proxy-config.yaml \
  --v=2 

PID=$!

sleep 5

# Save the PID into ETCD
echo "Saving the PID to ETCD"
ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 put proxy_pid $PID

if ps -p $PID > /dev/null; then
    echo -e "\n\nKube Proxy started and is running with PID: $PID \n\n"
else
    echo -e "\n\nKube Proxy has failed to start."
    #tail -n 10 /var/log/syslog 
fi