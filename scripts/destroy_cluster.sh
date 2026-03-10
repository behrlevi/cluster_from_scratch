#!/bin/bash

# The process IDs are stored in the ETCD, so it has to be functioning for this to work.

# Stop the API service
kill $(ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 get api_pid --print-value-only)