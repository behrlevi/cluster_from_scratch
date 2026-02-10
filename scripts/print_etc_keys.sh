#!/bin/bash

# ETCD stores the states in /var/lib/etcd
# wal (Write Ahead Log) - every change is appended here first
# snap - ETCD periodically compacts the data into snapshots here to prevent 'wal' from growing beyond a certain limit

ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 get "" --prefix --keys-only

# To add a test key-value pair
# ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 put my-key "Hello World"
