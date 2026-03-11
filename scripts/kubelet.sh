#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

if which kubelet >/dev/null 2>&1; then
    echo "The Kubelet is installed."
else
    wget -q --show-progress --https-only --timestamping https://dl.k8s.io/v1.26.0/bin/linux/amd64/kubelet
    cp kubelet /usr/local/bin/
    chmod +x /usr/local/bin/kubelet
fi

# Download and install the binary

# wget -q --show-progress --https-only --timestamping https://dl.k8s.io/v1.26.0/bin/linux/amd64/kubelet
# cp kubelet /usr/local/bin/
# chmod +x /usr/local/bin/kubelet

/usr/local/bin/kubelet \
  --kubeconfig=../kubeconfig \
  --config=../configs/kubelet-config.yaml \
  --cgroup-driver=systemd \
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \
  --v=2 \
  --fail-swap-on=false
  # --pod-manifest-path=/etc/kubernets/manifests \ # used for static pods

PID=$!
echo -e  "\n\nKubelet started with PID: $PID \n\n"

echo "Saving the PID to ETCD"
ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 put kubelet_pid $PID
sleep 5

if ps $PID &>/dev/null; then
  echo "The Kubelet is healthy."
else
  echo -e "The Kubelet exited with code $?"
fi
