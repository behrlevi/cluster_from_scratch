#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

if which kube-scheduler >/dev/null 2>&1; then
    echo "The Kube Scheduler is installed."
else
    cd ../Downloads
    wget https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kube-scheduler
    cp kube-scheduler /usr/local/bin/
    chmod +x /usr/local/bin/kube-scheduler
fi

# Download and install the binary

# wget https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kube-scheduler
# cp kube-scheduler /usr/local/bin/
# chmod +x /usr/local/bin/kube-scheduler

/usr/local/bin/kube-scheduler \
  --kubeconfig=../kubeconfig \
  --v=2 >/dev/null 2>&1 &

PID=$!
echo -e  "\n\nKube Scheduler started with PID: $PID \n\n"

# Save the PID into ETCD
echo "Saving the PID to ETCD"
ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 put scheduler_pid $PID

sleep 5

if ps $PID &>/dev/null; then
  echo "The Scheduler is healthy."
else
  echo -e "The Scheduler exited with code $?"
fi