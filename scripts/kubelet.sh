#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi


# Download and install the binary

# wget -q --show-progress --https-only --timestamping https://dl.k8s.io/v1.26.0/bin/linux/amd64/kubelet
# cp kubelet /usr/local/bin/
# chmod +x /usr/local/bin/kubelet

/usr/local/bin/kubelet \
  --kubeconfig=/home/lbehr/.kube/config \
  --config=/var/lib/kubelet/kubelet-config.yaml \
  --cgroup-driver=systemd \
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \
# --pod-manifest-path=/etc/kubernets/manifests \ # used for static pods
  --v=2 >/dev/null 2>&1 &

API_PID=$!

sleep 5

if ps -p $API_PID > /dev/null; then
    echo -e "\n\nKubelet started and is running with PID: $API_PID \n\n"
else
    echo -e "\n\nKubelet has failed to start."
    #tail -n 10 /var/log/syslog 
fi
