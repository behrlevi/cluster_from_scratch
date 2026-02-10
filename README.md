The main components of the cluster

ETCD - a key-value database storing cluster information
Kube API Server - manages requests and coordinates components in the cluster


I can create namespaces with only ETCD and the API Server, but when creating pods I'm getting an error:

"error looking up service account default/default: serviceaccount "default" not found"

ServiceAccount needs to be defined in the default namespace.

```
kubectl create serviceaccount default
```

Accounts can be checked with

```
kubectl get serviceaccounts
```


