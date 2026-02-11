# The main components of the cluster

- ETCD - a key-value database storing cluster information
- Kube API Server - manages requests and coordinates components in the cluster
- Kube Controller Manager - consists of multiple controllers tasked with controlling various aspects of the pod-cluster relationship
- Scheduler - assigns pods to nodes based on certain criteria

## ETCD
The first component we need for our cluster is the database reponsinble for keeping a single source of truth about the state of each resource, the ETCD database.

We can print the contets from it with
```
ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 get "" --prefix --keys-only
```
Having a fresh install, it will return nothing.

Try adding a sample key to it:
```
ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 put my-key "Hello World"
```
Now, running the previous 'get' will return our key.


## Kube API Server

Since we have our database ready, we can start the component responsible for accepting the requests made to the cluster either by the user or by the nodes.

We will be using kubectl to access the API endpoint. For this we need a config file (see 'kubeconfig' in the root of the repo). You can copy this over to ~/.kubec/config for convenience.
You should be able to query cluster resource with the kubectl command.
Make sure you have the correct context selected by running
```
kubectl config get-contexts
```
You can try for example:
```
kubectl get namespaces"
```

### Creating the service account

We can now create some resources, but we are getting an error when trying to create pods:

"error looking up service account default/default: serviceaccount "default" not found"

We need to define a ServiceAccount in the default namespace, what can be done with:

```
kubectl create serviceaccount default
```

Accounts can be checked with:

```
kubectl get serviceaccounts
```

When the service account is created we can try to create a pod, but we are getting back the following error:
"Error from server (ServerTimeout): No API token found for service account "default", retry after the token is automatically created and added to the service account"

This is because **Kubernetes Controller** is not generating a token for the account. Since we don't have a runner controller yet.

## Kube Controller Manager

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
Try running
```
kubectl describe pod testpod 
```
In the output you will see:
```
Events: none 
```
The pod will be stuck in a peding state since we don't have a scheduler installed yet. We are going to clear this block in the next step.

## Scheduler

The scheduler is responsible for assigning a pod to a node based on a set of criteria.

After we set up the scheduler, we finally gettings some events in the pod description: 
```
Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedScheduling  49s (x2 over 49s)  default-scheduler  no nodes available to schedule pods
```
This is because there are no kubelets registered with the scheduler.

## Kubelet

The Kubelet is running on the nodes (control or woker) and oversees activities by managing container operations such as starting and stopping containers based on instructions from the master scheduler.

**Prerequisites:**
- Make sure Systemd supports Systemd Cgroups. Check **/etc/containerd/config.toml** and search for **SystemdCgroup = true**. Without this you will get a CPU mount error.

- Swap needs to be disabled. You can disable it with: **sudo swapoff -a**

- We need to create the root certificate

```
# Generate the Private Key
openssl genrsa -out ca-key.pem 2048

# Generate the Public Certificate (Self-signed)
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kubernetes"

sudo mv ca.pem ca-key.pem /var/lib/kubernetes/

```

- Since we are moving to API Server version 1.26 now due to SystemdCrgoup support, we need to changed to a secure port and for that we also need to create a user to authenticate to the cluster.
Create a file contaning our user
```
echo 'admin-token,admin,1,"system:masters"' | sudo tee /var/lib/kubernetes/users.csv
```
Set the credentials (the token you created in Step 1)
```
kubectl config set-credentials admin --token="admin-token"
```

Update the context to pair the cluster with this user
```
kubectl config set-context default \
  --cluster=kubernetes \
  --user=admin
```

Select this context
```
kubectl config use-context default
```

After successfully starting the Kubelet, delete and recreate the testpod make sure its alligned with the currect configuration.
```
kubectl delete pod testpod
kubectl run testpod --image=nginx
```
In case the pod is stuck in the 'Terminating' state, you can use
```
kubectl delete pod testpod --grace-period=0 --force
``` 
Describe the pod again.
You will see a new network related error:
```
network is not ready: container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
```

 ## CNI
 ```
sudo mkdir -p /opt/cni/bin /etc/cni/net.d
wget https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
sudo tar -xzvf cni-plugins-linux-amd64-v1.4.0.tgz -C /opt/cni/bin
 ```

 Copy 10-mynet.conf into /etc/cni/net.d/