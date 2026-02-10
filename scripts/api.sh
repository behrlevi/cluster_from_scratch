#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

#wget https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-apiserver
#cp kube-apiserver /usr/local/bin/

export INTERNAL_IP=127.0.0.1

# Example
#ExecStart=/usr/local/bin/kube-apiserver \\
#  --advertise-address=${INTERNAL_IP} \\
#  --allow-privileged=true \\
#  --apiserver-count=3 \\
#  --authorization-mode=Node,RBAC \\
#  --bind-address=0.0.0.0 \\
#  --client-ca-file=/var/lib/kubernetes/ca.pem \\
#  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
#  --enable-swagger-ui=true \\
#  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
#  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
#  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
#  --etcd-servers=https://127.0.0.1:2379 \\
#  --event-ttl=1h \\
#  --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
#  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
#  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
#  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
#  --kubelet-https=true \\
#  --runtime-config=api/all \\
#  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
#  --service-cluster-ip-range=10.32.0.0/24 \\
#  --service-node-port-range=30000-32767 \\
#  --v=2

/usr/local/bin/kube-apiserver \
  --etcd-servers=http://127.0.0.1:2379 \
  --service-cluster-ip-range=10.0.0.0/16 \
  --insecure-bind-address=0.0.0.0 \
  --insecure-port=8080 \
  --service-account-key-file=/var/lib/kubernetes/service-account.pub \
  --v=2 >/dev/null 2>&1 &
API_PID=$!

sleep 5

echo -e  "\n\nThe API server started with PID: $API_PID \n\n"

# Health check

HEALTH=$(curl http://127.0.0.1:8080/healthz)

if [ "$HEALTH" == "ok" ]; then
	echo -e "\n\nThe API Server is healthy."
else
	echo -e "\n\nThe API Server ran into an error( Response: $HEALTH)"
	exit 1
fi

