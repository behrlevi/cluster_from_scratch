# The main components of the cluster

ETCD - a key-value database storing cluster information
Kube API Server - manages requests and coordinates components in the cluster
Kube Controller Manager - consists of multiple controllers tasked with controlling various aspects of the pod-cluster relationship

### What happens after setting up ETCD and the API server:

We can crate namespaces with only ETCD and the API Server, but when creating pods we are getting the following error:

"error looking up service account default/default: serviceaccount "default" not found"

ServiceAccount needs to be defined in the default namespace.

```
kubectl create serviceaccount default
```

Accounts can be checked with

```
kubectl get serviceaccounts
```

When the service account is created we can try to create a pod, but we are getting back the following error:
"Error from server (ServerTimeout): No API token found for service account "default", retry after the token is automatically created and added to the service account"

This is because **Kubernetes Controller** is not creating a token for the account. Since we don't have a runner controller yet.

Even though we are building a cluster without TLS, we need to generate two keys for token generation.

```
# Generate private key (for Controller Manager)
openssl genrsa -out /var/lib/kubernetes/service-account-key.pem 2048

# Generate public key (for API Server verification)
openssl rsa -in /var/lib/kubernetes/service-account-key.pem -pubout -out /var/lib/kubernetes/service-account.pub
```

The API server now needs a new argument for passing the service account keyfile
```
--service-account-key-file=/var/lib/kubernetes/service-account.pub
```

At this point we are able to create a pods with:
```
kubectl run testpod --image=nginx
```

The pod will be stuck in a peding state since we don't have a scheduler installed yet. We are going to clear this block in the next step.



