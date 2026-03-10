#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi


# wget https://dl.k8s.io/v1.26.0/bin/linux/amd64/kube-proxy
# cp kube-proxy /usr/local/bin/
# chmod +x /usr/local/bin/kube-proxy
# The proxy uses conntrack to apply firewall rules
# apt install -y conntrack

/usr/local/bin/kube-proxy \
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml \
  --v=2 2>&1 &

API_PID=$!

sleep 5

if ps -p $API_PID > /dev/null; then
    echo -e "\n\nKubelet started and is running with PID: $API_PID \n\n"
else
    echo -e "\n\nKubelet has failed to start."
    #tail -n 10 /var/log/syslog 
fi