# The main components of the cluster

- ETCD - a key-value database storing cluster information
- Kube API Server - manages requests and coordinates components in the cluster
- Kube Controller Manager - consists of multiple controllers tasked with controlling various aspects of the pod-cluster relationship
- Scheduler - assigns pods to nodes based on certain criteria
- Kubelet - running on each node and overseeing its activities
- CNI (Container Network Interface) - implements a network model

## ETCD
The first component we need for our cluster is the database reponsinble for keeping a single source of truth about the state of each resource, the ETCD database.

We can print its contets with
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

### Prerequisites

Initially I was planning to build the cluster without TLS encryption, but having to use the API server version 1.26 due to 
reliance on SystemdCgroup support, which requires secure connection, we will have to create and use a CA cert and a corresponding key.

Notice the **--kubelet-client-certificate=** and the **--kubelet-client-key=** arguments in the **scripts/api.sh** script.
These are needed for the the communication between the API server and the kubelet. This is specifically used for the *kubectl logs/exec port-forward* commands. The same certificate file has to be defined for the Kubelet in the config file, which in our case is located in **/configs/kubelet-config.yaml**.
Note that the the **x509: clientCAFile:** points to the same *ca.pem* file.

```
# Generate the Private Key
openssl genrsa -out ca-key.pem 2048

# Generate the Public Certificate (Self-signed)
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kubernetes"

# Move the keys to the expected directory
sudo mv ca.pem ca-key.pem /var/lib/kubernetes/

```

1. #### We will also create two keys for the service account used for token generation.

```
# Generate private key (for Controller Manager)
openssl genrsa -out /var/lib/kubernetes/service-account-key.pem 2048

# Generate public key (for API Server verification)
openssl rsa -in /var/lib/kubernetes/service-account-key.pem -pubout -out /var/lib/kubernetes/service-account.pub
```

2. #### Since the API server is expecting secure connection, we need a user to authenticate to the cluster.

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

- - -

Since we have our database ready, we can start the component responsible for accepting the requests made to the cluster either by the user or by the nodes.

We will be using kubectl to access the API endpoint. For this we need a config file (see 'kubeconfig' in the root of the repo). You can copy this over to *~/.kubec/config* for convenience.
You should be able to query cluster resource with the kubectl command.
Make sure you have the correct context selected by running
```
kubectl config get-contexts
```
You can try for example:
```
kubectl get namespaces"
```
- - -
### Creating the service account

We can now create some resources, but we are getting an error when trying to create pods:

```
error looking up service account default/default: serviceaccount "default" not found
```

We need to define a ServiceAccount in the default namespace, what can be done with:

```
kubectl create serviceaccount default
```

Accounts can be checked with:

```
kubectl get serviceaccounts
```

At this point we can try adding our first testpod with:
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
The pod will be stuck in a peding state since we don't have a **Scheduler** installed yet. We are going to clear this blocker in the next step.

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

### Prerequisites
- Make sure Systemd supports Systemd Cgroups. Check **/etc/containerd/config.toml** and search for **SystemdCgroup = true**. Without this you will get a CPU mount error.

- Swap needs to be disabled. You can disable it with: **sudo swapoff -a**

- Root certificate - this was already created during the installation of the API server

- - -

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
## Kube Controller Manager

### Background
A controller is responsible for monitoring a given resource type and driving the system towards the desired state. There is a separata controller responsible for nodes, replicas,
deployments, services, namespaces, persistent volumes etc. The controllers are checking the state of the monitored resource and making adjustments to it via the API.
All individual controllers are bundled into a single process known as the Kubernetes Controller Manager.

The API server now needs a new argument for passing the service account keyfile
```
--service-account-key-file=/var/lib/kubernetes/service-account.pub
```

 ## CNI

 The network plugin is used to declare and operate the network model used in the cluster.
 **Kubernetes Network Interface** (CNI) is a bundle of binaries which can be called by the container runtime.

- - -

To understand the process in a bit more detail, let me clarify the fundamentals.

The CNI plugins are not background processes or daemons, they are not running continously. Instead they are called by the container runtime, which is in our case **containerd**, only when a container is created or destroyed.

The process is as follows:
1. A freshly created contianer only has a loopback interface in an isolated network namespace.
2. The container runtime reads the configration file in **/etc/cni/net.d/**.
3. The type of network defined in the config triggers the corresponding binary from **/opt/cni/bin**.

- - -

The particular network configuration file provided represents a minimal architecture enabling pods to have IP addresses from the defined subnet.
For CNI to pick it up, you need to copy **configs/10-mynet.conf** into **/etc/cni/net.d/**.

To install the plugins, run */scripts/cni.sh*

At this point you should be able to run the nginx pod in the cluster.

## Kube Proxy

