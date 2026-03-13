#!/bin/bash

# The process IDs are stored in the ETCD, so it has to be functioning for this to work.

# Stop the API service
kill $(ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 get api_pid --print-value-only)

# Stop the Controller Manager
kill $(ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 get controller_manager_pid --print-value-only)

# Stop the Kube Proxy
kill $(ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 get proxy_pid --print-value-only)

# Stop the Kube Scheduler
kill $(ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 get scheduler_pid --print-value-only)

# Stop the Kubelet
kill $(ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 get kubelet_pid --print-value-only)