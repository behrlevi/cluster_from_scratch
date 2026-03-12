#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

if which etcd >/dev/null 2>&1; then
    echo "ETCD is installed."
else
    wget -q --https-only -P ../Downloads \
    "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"
    cd ../Downloads
    tar -xf etcd-v3.3.9-linux-amd64.tar.gz
    cd etcd-v3.3.9-linux-amd64
    cp etcd etcdctl /usr/local/bin/
    chmod +x /usr/local/bin/etcd
    chmod +x /usr/local/bin/etcdctl
fi

# Download and install the binary

# wget -q --https-only \
# "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"
# tar -xf etcd-v3.3.9-linux-amd64.tar.gz
# cd etcd-v3.3.9-linux-amd64
# cp etcd etcdctl /usr/local/bin/
# chmod +x /usr/local/bin/etcd
# chmod +x /usr/local/bin/etcdctl

export INTERNAL_IP=127.0.0.1
export ETCD_NAME=controller
export CONTROLLER0_IP=127.0.0.1

# Example etcd service configuration
#/usr/local/bin/etcd \
#  --name ${ETCD_NAME} \
#  --cert-file=/etc/etcd/kubernetes.pem \
#  --key-file=/etc/etcd/kubernetes-key.pem \
#  --peer-cert-file=/etc/etcd/kubernetes.pem \
#  --peer-key-file=/etc/etcd/kubernetes-key.pem \
#  --trusted-ca-file=/etc/etcd/ca.pem \
#  --peer-trusted-ca-file=/etc/etcd/ca.pem \
#  --peer-client-cert-auth \
#  --client-cert-auth \
#  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \
#  --listen-peer-urls https://${INTERNAL_IP}:2380 \
#  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \
#  --advertise-client-urls https://${INTERNAL_IP}:2379 \
#  --initial-cluster-token etcd-cluster-0 \
#  --initial-cluster controller-0=https://${CONTROLLER0_IP}:2380 \
#  --initial-cluster-state new \
#  --data-dir=/var/lib/etcd

# Without cert
/usr/local/bin/etcd \
  --name ${ETCD_NAME} \
  --initial-advertise-peer-urls http://${INTERNAL_IP}:2380 \
  --listen-peer-urls http://${INTERNAL_IP}:2380 \
  --listen-client-urls http://${INTERNAL_IP}:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://${INTERNAL_IP}:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster controller=http://${CONTROLLER0_IP}:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd 2>&1 &

PID=$!
echo -e "\n\nETCD started with PID: $PID"
