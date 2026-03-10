#!/bin/bash

chmod +x *.sh

bash etcd.sh
bash api.sh
bash controller-manager.sh
bash kube-proxy.sh
bash kube-scheduler.sh
bash kubelet.sh