#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi


# Download and install the binary

# wget https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kube-scheduler
# cp kube-scheduler /usr/local/bin/
# chmod +x /usr/local/bin/kube-scheduler

/usr/local/bin/kube-scheduler \
  --kubeconfig=/home/lbehr/.kube/config \
  --v=2 >/dev/null 2>&1 &

API_PID=$!

sleep 5

echo -e  "\n\nKube Scheduler started with PID: $API_PID \n\n"