#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

if which controller-manager >/dev/null 2>&1; then
    echo "The Controller Manager is installed."
else
    wget https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kube-controller-manager
    cp kube-controller-manager /usr/local/bin/
    chmod +x /usr/local/bin/kube-controller-manager
fi

# Download and install the binary

# wget https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kube-controller-manager
# cp kube-controller-manager /usr/local/bin/
# chmod +x /usr/local/bin/kube-controller-manager

# Sample configuration
# ExecStart=/usr/local/bin/kube-controller-manager \
#     --address=0.0.0.0 \
#     --cluster-cidr=10.200.0.0/16 \
#     --cluster-name=kubernetes \
#     --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \
#     --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \
#     --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \
#     --leader-elect=true \
#     --root-ca-file=/var/lib/kubernetes/ca.pem \
#     --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \
#     --service-cluster-ip-range=10.32.0.0/24 \
#     --use-service-account-credentials=true \
#     --v=2

# For version 1.13
# /usr/local/bin/kube-controller-manager \
#   --address=0.0.0.0 \
#   --cluster-cidr=10.200.0.0/16 \
#   --cluster-name=kubernetes \
#   --kubeconfig=/home/lbehr/.kube/config \
#   --leader-elect=true \
#   --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \
#   --use-service-account-credentials=true \
#   --v=2 #>/dev/null 2>&1 &

# For version 1.26
/usr/local/bin/kube-controller-manager \
  --bind-address=0.0.0.0 \
  --cluster-cidr=10.200.0.0/16 \
  --cluster-name=kubernetes \
  --kubeconfig=/home/lbehr/.kube/config \
  --leader-elect=true \
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \
  --use-service-account-credentials=true \
  --root-ca-file=/var/lib/kubernetes/ca.pem \
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \
  --v=2 >/dev/null 2>&1 &

PID=$!

sleep 5

# Save the PID into ETCD
echo "Saving the PID to ETCD"
ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 put controller_manager_pid $PID


echo -e  "\n\nKube Controller Manager started with PID: $PID \n\n"