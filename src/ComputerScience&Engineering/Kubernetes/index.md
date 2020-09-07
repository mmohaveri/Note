<img src="../../assets/kubernetes-logo.png" width="130px">

# Kubernetes

## Kubernetes of Ducker Swarm?

Notes from [Docker Swarm or Kubernetes – Pick your framework!](https://www.youtube.com/watch?v=1dgUXNVQS5o&t=755s)

A comparison between Docker Swarm and Kubernetes, good for understanding basic components of a kubernetes cluster from
point of view of an end user.

## Kubernetes Basic Architecture

Notes from [Inside Kubernetes: An Architectural Deep Dive with Anthony Nocentio](https://youtu.be/d5Rmu3fboiQ?t=300)

### What is Kubernetes?

- A Container Orchestrator

### Benefits of Kubernetes

- Managing (desired) state, starting things and keeping them up.
  - Ability to absorb change quickly
  - Ability to recover quickly
  - Speed and consistency of deployment
- Infrastructure Abstraction
  - Hide complexity in cluster
  - Ability to upscale and downscale easily
- Persistent application access endpoint

### Kubernetes API Objects

Represent resources in the system

- Pods
  - Your application or service
  - Basic unit of work and scheduling
  - One or more tightly coupled containers
    - Generally one container in each pod, unless there’s a very good reason to not to
  - Ephemeral, pods can’t be redeployed.
    - You should decouple computation and storage. 
- Controllers
  - Create and manage Pods
  - Describe your desired state
  - Respond to Pod state and health.
    - Using health-check and liveness-probes.
  - Different types based on your needs
    - Deployment & ReplicaSet
    - StatefulSet
    - DemonSet
- Services
  - Add persistency to our ephemeral world
    - Provides a networking abstraction for Pod access
    - IP and DNS name for the service
    - Load balancing
      - Redeployed Pods automatically updated
      - Scaled by adding/removing Pods
- Storage
  - Persistent Volumes
    - Before them we had (regular) Volumes
      - Tightly coupled individual Pods with individual storages.
    - Pod independent storage
    - Storage defined by administrators in the cluster level
  - Persistent Volume Claims
    - The Pod “claims” the PV, Kubernetes assigns a PV matching the requirements to the Pod. 
- etc.

### Kubernetes Architecture

#### Master

Runs a couple of services

- API Server: Main Communication hub (stateless)
- Cluster Store: Persist the state of deployments
  - Implemented by etcd key-value store
- Scheduler: Figures out where to run Pods in the cluster
- Controller manager: Implements controllers (the things that make sure the cluster stays in the desired state)

#### Kubectl

The tool that we use to interact with API server

#### Nodes

The thing that does the actual work, runs Pods, etc.
- Kublet
   - Monitor API server (pooling) for changes in state and works assigned to the node.
- Kube Proxy
  - Implements network services
    - Generally IPtables, exposes everything that’s running inside applications on an node onto the network
- Container runtime
  - Conventionally docker, but can be anything that supports an specific API
  - Pulls the containers off the registry and run them inside the node

By default master **won’t run** user workloads (is tainted from scheduling). Master components are deployed as Pods as well but they’ll start in a special way and will always run on the master.

You can change this, but in a production environment you **SHOULD NOT**.

### Deploying Applications 

Kubernetes uses a declarative approach to deployments. You describe your desired state in a YAML or json manifest.

#### Deploying Applications Process

1. **Kubectl** submits a YAML to kubernetes (kubectl apply -f replicaset-manifest.yaml)
2. **API Server** authenticates the request
3. **API Server** authorizes whether the user has the authority to do the thing it wants to do (creating a ReplicaSet and pods) or not based on the Role Based Security (RBAC).
4. If everything is ok, **API Server** stores the manifest inside the **Cluster Store**.
5. **Scheduler** and **Controller Manager** are watching changes on **Cluster Store**.
6. After getting the notification from **Cluster Store**, ReplicaSet controller reads changes and creates needed Pods for the ReplicaSet by storing needed Pod definitions into **Cluster Store**.
7. After getting notification from **Cluster Store** (about the unscheduled Pods), **Scheduler** figures out (based on required and available resources) on what node the Pods should run and writes this information back to **Cluster Store**.
8. **Kubelet** is pooling the **API Server** about any work, and gets back with the list of Pods that it’s supposed to run.
9. **Kubelet** informs **Container Runtime** to download and run the needed containers.
10. **Kubelet** informs **KubeProxy** about needed services and it implements them.

### Building Production Ready Clusters

- Scalability (enough resources Nodes)
- Inter-cluster communication (Full mesh networking, all things needed for our applications and our nodes to communicate to each other in a Highly Available fashion).
- High Availability resources
  - API Server (Load Balanced)
  - Cluster Store, etcd (Multiple Replicas)
- Disaster Recovery
  - etcd Backup
- Persistent Volumes

## Hammering together the most basic Kubernetes cluster

Notes from [Deep Dive into Kubernetes Internals for Builders and Operators](https://www.youtube.com/watch?v=3KtEAa7_duA&t=288s)

An step by step presentation for manually setting up a basic kubernetes cluster.

It's specially good because it adds different components one by one when something goes wrong, so you'll get a good idea
why an specific component is needed.

### What do we want to achieve?

Learn how to run the most basic kubernetes cluster from scratch. In other words, how to create the most basic cluster capable of running the following commands successfully:

```bash
kubectl create deployment web --image=nginx
kubectl scale deployment web --replicas=3
kubectl expose deployment web --port=80
```

### Kubernetes architecture

[Kubernetes architecture](assets/kuber.png)

### What happens when you create a deployment

1. kubectl generates a YAML manifest describing a Deployment
2. The manifest is sent to the Kubernetes API server
3. The Kubernetes API server validates the manifest and persists it to etcd
4. Deployment controller wakes up and creates needed ReplicaSets for the deployment and persists the result on etcd.
5. ReplicaSet controller wakes up and creates needed Pods for the ReplicaSets and stores the results on etcd (Pods status: PENDING).
6. Scheduler wakes up and assigns Nodes to each Pod and stores the results on etcd (Pods status: Node x). 
7. Kubelet asks the API Server about new work to do and gets back the newly created Pods (Pods status: CREATING).
8. Kubelet informs Container Runtime about new Pods and Container Runtime creates needed containers.
9. Kubelet informs Networking about needed changes in services and Networking applies needed changes.
10. Kubelet informs API Server about newly created Pods and API Server stores the results on etcd (Pod status: RUNNING) 

[Kubernetes deployment process](assets/kuber.png)

### Let’s build a basic cluster

#### What we need

- Linux Machine
  - 86_64 architecture
  - 2 GB RAM
  - 1 CPU
  - Root access (For Docker and Kubelet)
- Binaries:
  - etcd
  - Kubernetes (kubectl, kube-apiserver, kube-controller-manager, kubelet, kube-proxy, …)
  - docker

#### The Process

##### Create a deployment

- Create deployment
```bash
kubectl create deployment web --image=nginx
```
```
Fails to connect to API server, because it's not running!
```

- Run kube-apiserver
```bash
kube-apiserver
```
```
Missing list of etcd servers!
````

- Run etct 
```bash
etcd
```
```
Ok
```

- Re-run kube-apiserver
```bash
Kube-apiserver --etcd-servers=http://localhost:2379
```
```
Ok
```

- Re-run deployment creation
```bash
kubectl create deployment web --image=nginx
```
```
Deployment created, but no ReplicaSet or Pod created!
```
This is because the Controller Manager for deployments is not running!

- Run Controller Manager
```bash
kube-controller-manager --master=http://localhost:8080
```
```
ReplicaSet is created, but still no Pod!

In output of kube-controller-manager:
  No **API token** found for **service account** “default”, retry after the token is automatically created and added to the service account.
```
Service Account Token is a bearer token automatically added to Pods by API server. It allows in-cluster processes to talk to the API server.
We need a system to generate and sign ServiceAccountTokens, but for the purpose of this tutorial we’ll simply tell the API server to not use the service account token.

- Tell API server to ignore service account tokens
```bash
kubectl edit sa default
```
```
At the end of the Service Account definition add “automountServiceAccountToken: false”
```
```
Pod is created, but with status “Pending”!
```
Because there is no scheduler to assign the pod to a Node. Also, there is no Node!

- Run kube-scheduler
```bash
kube-scheduler --master=http://localhost:8080
```
```
Ok
```

- Run a kubelet
```bash
kubelet
```
```
Needs a container engine!
```
Kubelet does not run containers itself. Instead, it utilizes other container engines like **docker**, **rkt**, **containerd**, etc.

- Start docker
```bash
dockerd
```
```
Ok
```

- Re-run kubelet
```bash
kubelet
```
```
It runs, but nothing happens, because it's in standalone mode!
```
We need to create a YAML manifest telling kubelet about the API server it’s suppose to connect to.

- Create the config file for kubelet
```bash
kubectl config set-cluster localhost --server=http://localhost:8080
kubectl config set-context localhost --cluster=localhost
kubectl config use-context localhost
```
```
Successfully created a config file in .kube/config.

It contains a cluster named “localhost”, a context named “localhost” (marked as “default” context) which refers to the “localhost” cluster.
```

```bash
cat .kube/config
```
```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: http://localhost:8080
  name: localhost
- context:
    cluster: localhost
    user: ””
  name: localhost
current-context: localhost
users: []
preferences: {}
```

- Re-run kubelet
```bash
Kubelet --kubeconfig ~/.kube/config
```
```
Ok, the pod’s status goes to ContainerCreating and after a while goes to Running.
```
At this stage if we curl its IP address (obtained from kubectl get pods -o wide) we’ll see “welcome to nginx” page.

##### Create a service and setup Pod-to-Service networking

- Create service
```bash
kubectl expose deployment web --port=80
```
```
Service created, but when curl its IP address nothing happens!
```
It’s kube-proxy’s job to setup some IPtable rules for each service and connect them to desired Pods.

- Start kube-proxy
```bash
kube-proxy --master=http://localhost:8080
```
```
Ok
```
Now if culr service IP’s again we’ll see “welcome to nginx” page.

##### Add a new Node

- Run kubelet on a new server
  - First copy .kube/config to the new machine and change cluster IP address to masters IP address.
  - Start dockerd

```bash
Kubelet --kubeconfig ~/.kube/config
```
```
Fails to connect to the API server!
```
By default kube-apiserver listens on localhost, we need to change it.

- Tell API server to listen on all interfaces
```bash
kube-apiserver --etc-servers=http://localhost:2379 --address 0.0.0.0
```
```
Ok
```
Restart other components of the control plane (kube-controller-manager, kube-scheduler, etc.) as they exit when kube-apiserver exits.

After that the node will join the cluster successfully.

- Create a new deployment
```bash
kubectl create deployment httpenv --image=jpetazzo/httpenv
kubectl scale deployment httpenv --replicas=3
kubectl expose deployment httpenv --port=8888
```
```
Everything seems ok, but if we try to send a set of requests, we’ll find out that only one Pod is replying!
```
If we look closer to the output of `kubectl get pods -o wide` we’ll find out that pods on different nodes might have the same IP addresses!

It's because kubelet does not deal with the network and delegates this job to the container engine. So, when we start a new node container engine of that node is not aware of the existence of other containers on other nodes and might reuse an IP address.

To solve this issue we have two options: “kube-net” and “CNI”
> kube-net a simple implementation for networking, each node will have a subnet, kube-net pick an IP address from the pool, assign it to the Pod, and put the Pod on a bridge.

- Re-run kubelet with a network-plugin (on both nodes)
```bash
kubelet --kubeconfig .kube/config --network-plugin=kubenet --pod-cidr=10.99.n.0/24
```
```
Pod IPs are still the same!
```
Because kubelet does not touch running Pods, we need to delete them in order for them to be re-created. 

- Delete pods
```bash
kubelet delete pods --all
```
```
Pods have different IPs, but we can not ping pods on Node2 from Node1!
We need to set up routing to tell the Node1 that Node2’s Pods subnet is on the Node2.
```

- Add routing to Node1
```bash
ip route add 10.99.2.0/24 via <Node2 IP>
```
```
Ping still fails due to Node2 firewall rules!
```

- Allow all packets on Node2!
```bash
iptables -I FORWARD -j ACCEPT
```
```
Ok
```

##### Using CNI instead of kubenet

Configuring the network using kubenet can be a little hard and non-trivial, so we want to try the second option, CNI. CNI, or Container Network Interface, makes our life easier because:
- Allows us to decouple network configuration from Kubernetes
  - It can allocate IPs to Pods arbitrarily, instead of from a subnet.
  - It lets you allocate IPs without connecting containers to a bridge
- Is implemented by a set of plugins
  - Binary executables invoked by kubelet
  - Can be combined and chained together if needed
- Responsible for:
  - Allocating IP addresses to containers
  - Configuring the network for containers

We’ll be using kube-router for our CNI, it will:
- Provide pods connectivity
  - Route Pod traffics between nodes (no tunnel, no new protocol)
- Internal service connectivity (replacing kube-proxy)
  - Implemented by IPVS
- can act as Network Policy Controller allowing us to implement firewalls between Pods.

How it works:

- A kube-router daemon runs on every node
- kube-router connects to API server and obtains the node’s podCIDR
- Inject the result into local CNI config file
- kube-router connects to API server and obtains the all nodes IP addresses
- Establish a full mesh BGP peering with other nodes
  - It allows us to interconnect our “Pod Network” with other systems.
- Exchange routes over BGP
- Add routes to the linux kernel

- Run kubelet using CNI
```bash
kubelet --kubeconfig .kube/config --network-plugin=cni
```
```
Complaints about not having a CNI configuration!
```
The CNI configuration will be automatically added by a DemonSet.

- Run kube-router as DaemonSet
  Create a manifest for the DaemonSet:
```bash
kubectl create -f cni.yaml
```
Fails because it wants to run a privileged container.
```

- Re-run API server while allowing privileged containers:
```bash
kube-apiserver --etcd-servers=http://localhost:2379 --address 0.0.0.0 --allow-privileged
```
```
Complaints about not having a CNI configuration!
```
Also we have to re-run kube-scheduler and kube-controller-manager

- re-run kube-router as DaemonSet
```bash
kubectl create -f cni.yaml
```

- Re-run kubelet using CNI
```bash
kubelet --kubeconfig .kube/config --network-plugin=cni
```

### What’s missing here?
- Security
  - Role Based Access Control (RBAC)
    - Create TLS certificates for all elements in the control plane:
      - etcd
      - API Server
      - Controller Manager
      - Scheduler
    - Create individual certificates for nodes
    - Create the Service Account Tokens for Pods
      - The Controller Manager will generate these tokens
      - The API Server will validate these tokens
  - Node security
    - NodeRestriction admission controller
      - Allows kubelets to only update their own data
    - Node Authorizer
      - Prevents kubelets from accessing data that they shouldn’t
        - Only authorize access to a configmap if a Pod is using it
        - Etc.
    - Bootstrap tokens
      - Allow an easy, safe, and dynamic way for adding new nodes to the cluster
- Availability
  - Highly Available API Server

## Pod Networks and comparison of popular CNI plugins

Notes from [Comparing Kubernetes CNI Providers: Flannel, Calico, Canal, and Weave](https://rancher.com/blog/2019/2019-03-21-comparing-kubernetes-cni-providers-flannel-calico-canal-and-weave/)

###  Introduction

**Container networking** is the mechanism through which containers can optionally connect to other containers, the host, and outside networks like the internet. Container runtimes offer various networking modes. As an example docker provides none, host, and bridge networking modes.

CNI, [Container Network Interface](https://github.com/containernetworking/cni), is a standard interface for programs to dynamically configure networks and resources of a container. [It's spec](https://github.com/containernetworking/cni/blob/master/SPEC.md) outlines a plugin interface for container runtimes to coordinate with plugins to configure networking.

Plugins are responsible for provisioning and managing an IP address to the interface and usually provide functionality related to IP management, IP-per-container assignment, and multi-host connectivity.

The container runtime calls the networking plugins to allocate IP addresses and configure networking when the container starts and calls it again when the container is deleted to clean up those resources.

The runtime decides on the network a container should join and the plugin that it needs to call. The plugin then adds the interface into the container network namespace as one side of a veth pair. It then makes changes on the host machine, including wiring up the other part of the veth to a network bridge. Afterwards, it allocates an IP address and sets up routes by calling a separate IPAM (IP Address Management) plugin.

Kubernetes networking model demands [certain network features](https://kubernetes.io/docs/concepts/cluster-administration/networking/#the-kubernetes-network-model). In short it demands that:
- Each Pod gets its own IP address
- Pods on a node have the ability to communicate with all Pods on all nodes without NAT
- Agents on a node have the ability communicate with all pods on that node

CNI allows kubelet to automatically configure networking for the Pods by calling the plugins at appropriate times. These plugins do the work of making sure that Kubernetes’ networking requirements are satisfied and providing the networking features that cluster administrators require.

### Some network terminology

- **Layer 2 networking** or **data link layer** deals with delivery of frames between two adjacent nodes on a network, e.g. Ethernet.
- **Layer 3 networking** or **network layer** routes packets between hosts on top of the layer 2 connections, e.g. IPv4 & IPv6.
- **Layer 4 networking** or **transport layer** is responsible for end-to-end communication over layer 3, e.g TCP & UDP, and provides additional services such as connection-oriented communication, reliability, flow control, multiplexing, etc.
- **Overlay network** is a virtual network built on top of an existing network. They are often used to provide useful abstractions on top of existing networks and to separate and secure different logical networks.
- **Encapsulation** is the process of wrapping network packets in an additional layer to provide additional context and information. In overlay networks, encapsulation is used to translate from the virtual network to the underlying address space to route to a different location.
- **VXLAN**, **virtual extensible LAN**, is an encapsulation and overlay protocol. It is used to help large cloud deployments scale by encapsulating layer 2 Ethernet frames within UDP datagrams. It’s a VLAN extension that offers more flexibility and power.
- **Mesh Network** is a network in which each node connects to many other nodes, to cooperate on routing and achieve greater connectivity. Network meshes provide more reliable networking by allowing routing through multiple paths. The downside of a network mesh is that each additional node can add significant overhead.
- **BGP**, **border gateway protocol**, is a protocol to manage how packets are routed between edge routers. It helps figure out how to send a packet from one network to another by taking into account available paths, routing rules, and specific network policies. BGP is sometimes used as the routing mechanism in CNI plugins instead of encapsulated overlay networks.
- **IPVS**, **IP Virtual Server**, is a layer 4 load balancer implemented as part of the linux kernel. It can direct requests for TCP/UDP-based services to the real servers, making services of the real servers appear as virtual services on a single IP address.
- **iptables** is a linux utility program that allows configuration of  the IP packet filter rules of the Linux kernel firewall.

### Different CNI options

When it’s time to choose a CNI plugin, you have many options to choose from, some of the more popular options are Calico, Flannel, Canal, Weave, and Kube Router.
In the following segments we’ll try to compare these options and help you to choose more wisely.

#### [Flannel (5.6k ⭐)](https://github.com/coreos/flannel)

Developed by CoreOS, Flannel is one of the most mature and most popular CNI plugins available, intended to allow for better inter-container and inter-host networking. It is packaged as a single binary called flanneld, and uses the cluster’s existing etcd to store its state information.

Flannel configures a layer 3 IPv4 overlay network. A large internal network is created that spans across every node within the cluster. Within this overlay network, each node is given a subnet to allocate IP addresses internally. As pods are provisioned, the Docker bridge interface on each node allocates an address for each new container.

Pods within the same host can communicate using the Docker bridge, while pods on different hosts will have their traffic encapsulated in UDP packets by flanneld for routing to the appropriate destination. For this reason, you’ll need to run flanneld on all your nodes.

Flannel has several different types of backends available for encapsulation and routing. The default and recommended approach is to use VXLAN, as it offers both good performance and is less manual intervention than other options.
Flannel has two major limitations, lack of support for multiple networks and [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/). The latter can be overcomed by utilizing Canal. 

Overall, Flannel is a good choice for most users. From an administrative perspective, it offers a simple networking model that sets up an environment that’s suitable for most use cases when you only need the basics. In general, it’s a safe bet to start out with Flannel until you need something that it cannot provide.

#### [Calico (1.9k ⭐)](https://github.com/projectcalico/calico)

Calico is another popular networking option best known for its performance, flexibility, and power. Calico concerns itself not only with providing network connectivity between hosts and pods, but also with network security and administration. The [Calico CNI plugin](https://github.com/projectcalico/cni-plugin) wraps Calico functionality within the CNI framework.

On a freshly provisioned Kubernetes cluster, that has Calico’s [system requirements](https://docs.projectcalico.org/getting-started/kubernetes/requirements), Calico can be deployed quickly by applying a single manifest file. If you are interested in Calico’s optional network policy capabilities, you can enable them by applying an additional manifest to your cluster.

Calico uses BGP to configure the layer 3 network to route packets between hosts. This means that packets do not need to be wrapped in an extra layer of encapsulation when moving between hosts. Besides the performance improvements, this approach allows for more conventional troubleshooting when network problems arise. 

Calico also provides some advanced network features, like [Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/), Istio integration, etc. Its Istio integration interprets and enforces policy for workloads within the cluster both at the service mesh layer and the network infrastructure layer. 

Calico is a good choice when performance and features like network policy are important. It’s especially a good choice when you want to be able to control your network instead of just configuring it once and forgetting about it.

#### Canal

Canal is combining Calico and Flannel together. It’s the intersection of the two projects and tries to achieve the best of both worlds. The networking layer is the simple overlay network provided by Flannel. The network policy capabilities are provided by Calico’s powerful networking rule evaluation to provide additional security and control.

#### [Weave Net (5.9k ⭐)](https://github.com/weaveworks/weave)

Weave Net is another CNI-capable networking option for Kubernetes that creates a full mesh overlay network between the nodes of a cluster, allowing for flexible routing between participants.

Weave relies on a routing component installed on all hosts. These components, routers, exchange topology information to maintain an up-to-date view of the available network landscape. When looking to send traffic to a pod on a different node, the router choose between sending via “fast datapath” or falling back on the “sleeve” packet forwarding method.

Fast datapath is an approach that relies on the kernel’s native Open vSwitch datapath module to forward packets to the appropriate pod without moving in and out of userspace multiple times. The Weave router updates the Open vSwitch configuration to ensure that the kernel layer has accurate information about how to route incoming packets.

Sleeve mode is a backup option for the times that networking topology isn’t suitable for fast datapath routing. It’s an encapsulation mode that can route packets in instances where fast datapath does not have the necessary routing information or connectivity.

As traffic flows through the routers, they learn which peers are associated with which MAC addresses, allowing them to route more intelligently with fewer hops for subsequent traffic.

Weave also provides network policy capabilities. It also provides an easy way to encrypt your network traffic, using NaCl (salt) for sleeve traffic, and IPSec for fast datapath traffic.

Weave is a great option for those looking for feature rich networking without adding a large amount of complexity or management. It is relatively easy to set up, offers many built-in and automatically configured features, and can provide routing in scenarios where other solutions might fail, although the mesh topography may cause performance problems in large networks.

#### [Kube Router (1.5k ⭐)](https://github.com/cloudnativelabs/kube-router)

Kube-router is a Layer 3 CNI plugin for Kubernetes aiming to provide operational simplicity and high performance. It uses BGP for L3 networking, iptables for network policies and IPVS for Kube Services Proxy (if setup to replace kube-proxy).

One of the key design tenets of Kube-router is to use standard Linux networking stack and toolset. There are no overlay networks, just plain good old Linux networking. It will result in a lightweight all-in-one solution with a small footprint.

It also does not have any dependency on a data store and does not implement any custom solution for pod CIDR allocation to the nodes and uses standard CNI plugins so does require any additional CNI plugin.

With all features enabled, kube-router is a lean yet powerful alternative to several network components used in typical Kubernetes clusters.

#### [Multus (810 ⭐)](https://github.com/intel/multus-cni)
Multus is a CNI plugin that provides multiple network interface support to pods. For each interface Multus delegates CNI calls to secondary CNI plugins. 

### Ease of installation and performance comparison

Based on [this article](https://itnext.io/benchmark-results-of-kubernetes-network-plugins-cni-over-10gbit-s-network-36475925a560), the easiest CNI to install is Flannel. It’s also one of the most performant ones, with high performance in all categories (TCP, UDP, HTTP, etc.) and low resource consumption.

If you need to support Network Policies, you can use Canal (if you already have a cluster running with Flannel) or Calico. Just keep in mind that both Calico and Canal need manual MTU selection, as they don’t find the best MTU possible automatically.

## [Kubernetes the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

An step by step guide for manually setting up a multi-master kubernetes cluster.

The purpose of this guide is to understand Kubernetes working mechanism in a deep way and is suitable for
System Admins and Cluster Managers.

Keep in mind that the final result is **not suitable** for production.

## Tutorials

- [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-create-a-kubernetes-cluster-using-kubeadm-on-ubuntu-18-04)
- [Platform 9](https://platform9.com/docs/install-kubernetes-the-ultimate-guide/)
- [PhoenixNAP](https://phoenixnap.com/kb/how-to-install-kubernetes-on-centos)

---

## Watching list

### Cluster setup

- [From Minikube to Production, Never Miss a Step in Getting Your K8s Ready](https://www.youtube.com/watch?v=q3pfpzWPgK8)
- [Kubeadm Deep Dive](https://www.youtube.com/watch?v=DhsFfNSIrQ4)
- [Minikube](https://www.youtube.com/watch?v=xdoOmSSCxo8)

### Security

- [How This Innocent Image Had a Party in My Cluster](https://www.youtube.com/watch?v=Ut3rrtMOkXk)
- [Cloud Native Policy Deep Dive](https://www.youtube.com/watch?v=GSeC49v1NRw)
- [Handling Container Vulnerabilities with Open Policy Agent](https://www.youtube.com/watch?v=WKE2XNZ2zr4)
- [Securing Container Delivery with TUF](https://www.youtube.com/watch?v=GJP0_DEW-ro)
- [Securing Your Healthcare Data with OPA](https://www.youtube.com/watch?v=X8AhoSFXSzU)
- [Open Policy Agent Deep Dive](https://www.youtube.com/watch?v=E91yXNzcwx4)
- [Open Policy Agent Introduction](https://www.youtube.com/watch?v=tGVxKU5jRHY)
- [Threat Modelling: Securing Kubernetes Infrastructure & Deployments](https://www.youtube.com/watch?v=_T-5QhZieH8)
- [How Many CPU Cycles I Need to Invest in Cloud Native Security?](https://www.youtube.com/watch?v=DAnakO5QmUY)
- [Help, My Cluster in on the internet: Container Security Fundamentals](https://www.youtube.com/watch?v=lEH7lEcCNeQ)
- [Getting Started With Cloud Native Security](https://www.youtube.com/watch?v=MisS3wSds40)
- [Where Are Your Images Running? Stop Worrying and Start Encrypting](https://www.youtube.com/watch?v=tRWMxuMEy9I)

### Application best practices

- [What's an Application in Kubernetes?](https://www.youtube.com/watch?v=Pm4e9dttI-o)
- [Using SOPS, Kube Secrets and a CD Pipeline For Secure Configuration](https://www.youtube.com/watch?v=Gy7cTsbxbDI)
- [Kubernetes Patterns](https://www.youtube.com/watch?v=eJmNSYvelSw)
- [DevOps Patterns and Antipatterns for Continuous Software Updates](https://www.youtube.com/watch?v=zLmsVaw2TSw)
- [Simplify Your Cloud Native Application Packaging and Deployments](https://www.youtube.com/watch?v=q1ioO9Tl4J8)
- [Zero Downtime Deployments: Controlling Application Rollouts and Rollbacks](https://www.youtube.com/watch?v=rh6EtXiNOj4)
- [Towards a Standardized Application Definition Model for Kubernetes](https://www.youtube.com/watch?v=JbhtR6VaVCM)
- [KinD-ly Validating Your K8s Apps Automatically Per PR](https://www.youtube.com/watch?v=Yt5wpZ6raDA)
- [Deliver Your Cloud Native Application with Design Patterns as Code](https://www.youtube.com/watch?v=PHajuKqjNs8)

### Kubernetes components

- [Introduction to containerd](https://www.youtube.com/watch?v=q0xt_JrJiIg)
- [containerd Deep Dive](https://www.youtube.com/watch?v=aVReM1D82iY)
- [Intro: Harbor - Enterprise Cloud Native Artifact Registry](https://www.youtube.com/watch?v=zGK0Nre21Eo)
- [Deep Dive: Harbor - Enterprise Cloud Native Artifact Registry](https://www.youtube.com/watch?v=XOP6DKULmfk)
- [An Introduction to Helm](https://www.youtube.com/watch?v=x2w6T0sE50w)
- [Deep Dive into Helm](https://www.youtube.com/watch?v=UfASpCJOdiw)
- [Introduction to CNI](https://www.youtube.com/watch?v=YWXucnygGmY)
- [Deep Dive: CNI](https://www.youtube.com/watch?v=0tbnXX7jXdg)
- [Cluster API: A Guide to Get Started](https://www.youtube.com/watch?v=EgMNy-wAm4A)
- [Cluster API Deep Dive](https://www.youtube.com/watch?v=9SfuQQeeK6Q)
- [Kubernetes Networking Intro and Deep-Dive](https://www.youtube.com/watch?v=tq9ng_Nz9j8)

- [In a Container, Nobody Hears Your Screams: Next Generation Process Isolation](https://www.youtube.com/watch?v=NQrs1mpfDNc)
- [Managing Applications in Production: Helm vs. ytt and kapp](https://www.youtube.com/watch?v=WJw1MDFMVuk)
- [Scaling Kubernetes Networking Beyond 100k Endpoints](https://www.youtube.com/watch?v=a6SfbeM06Qo)
- [Dynamic Configuration with ComponentConfig and the Control Loop](https://www.youtube.com/watch?v=2SKJ-L10vuQ)
- [Sateless Fluentd with Kafka](https://www.youtube.com/watch?v=0G9lUnBBM6c)
- [Advanced Logging with Fluent Bit](https://www.youtube.com/watch?v=F73MgV_c2MM)

#### Service Mesh, Tracing

- [Building the Cloud Native Telco with Network Service Mesh](https://www.youtube.com/watch?v=zPKCZxHrERU)
- [Jaeger Intro](https://www.youtube.com/watch?v=UNqilb9_zwY)
- [Enboy, Take the Wheel: Real-Time Adaptive Circuit Breaking](https://www.youtube.com/watch?v=CQvmSXlnyeQ)
- [Build and Automatic Canary Release Pipeline in a Kubernetes native Way](https://www.youtube.com/watch?v=xK1QD_aZWq8)
- [eBPF and Kubernetes: Little Helper Minions for Scaling Microservices](https://www.youtube.com/watch?v=99jUcLt3rSk)
- [Deep Dive: Linkerd](https://www.youtube.com/watch?v=GJVzSqYrflc)
- [Jaeger Deep Dive](https://www.youtube.com/watch?v=BWtNelj_XUc)
- [Observibility at Scale: Running OpenTelemetry Across and Enterprise](https://www.youtube.com/watch?v=Dswj-nPy_Fs)
- [Ingress on Rails: Use Community Tools to Automate Ingress PRovisioning](https://www.youtube.com/watch?v=Y7-X-htiVw0)
- [Building a Service Mesh From Scratch - The Pinterest Story](https://www.youtube.com/watch?v=CoLionpKa9c)
- [What You Didn't Know About Ingress Controllers' Performance](https://www.youtube.com/watch?v=6Dqon7Fs7kg)
- [Episode IV: A New Network Service Mesh](https://www.youtube.com/watch?v=STxfzYMwIEs)
- [Network Isolation for 1500 Microservices](https://www.youtube.com/watch?v=kVhSbHoBSH0)
- [Building a Distributed API Gateway with a Service Mesh](https://www.youtube.com/watch?v=YeK34lItg2Q)
- [Using BPF in Cloud Native Environments](https://www.youtube.com/watch?v=QhPXf4YFaJg)
- [Intro: Linkerd](https://www.youtube.com/watch?v=PxRAis8afAU)

#### Monitoring

- [Prometheus Introduction](https://www.youtube.com/watch?v=PzFUwBflXYc)
- [Prometheus Deep Dive](https://www.youtube.com/watch?v=Xx16tAoqw70)
- [Scaling Prometheus: How We Got Some Thanos into Cortex](https://www.youtube.com/watch?v=Z5OJzRogAS4)
- [Predictable Performance through Promethous and Topology Aware Scheduling](https://www.youtube.com/watch?v=WU0nYicYanQ)
- [Thanos: Cheap, Simple and Scalable Prometheus](https://www.youtube.com/watch?v=Wroo1n5GWwg)
- [Make Prometheus Use Less Memory and Restart Faster](https://www.youtube.com/watch?v=suMhZfg9Cuk)
- [OpenTelemetry Agent and Collector: Telemetry Built-in into All Software](https://www.youtube.com/watch?v=cHiFSprUqa0)
- [Turn It Up to a Million: Ingesting Millions of Metrics with Thanos Receive](https://www.youtube.com/watch?v=5MJqdJq41Ms)
- [What You Need to Know about OpenMetrics](https://www.youtube.com/watch?v=C-BJAzCiMyY)
- [Better Histograms for Prometheus](https://www.youtube.com/watch?v=HG7uzON-IDM)
- [OpenTelemetry Auto-Instrumentation Deep Dive](https://www.youtube.com/watch?v=uMoLw5GEX2E)
- [Hubble - eBPF Based Observability for Kubernetes](https://www.youtube.com/watch?v=8WCbGSCyDSo)

#### Auto Scaling

- [Introduction to Autoscaling](https://www.youtube.com/watch?v=VP7MzegrjTw)
- [Autoscaling at Scale: How We Manage Capacity @Salando](https://www.youtube.com/watch?v=XTUsVK9F_Ds)
- [Do The Math: Auto-Scaling Applications with Kubernetes](https://www.youtube.com/watch?v=6RZNx58GKsg)
- [Deep Dive into Autoscaling](https://www.youtube.com/watch?v=UZ9NYQ-dpdw)
- [Autoscaling and Cost Optimization on Kubernetes: From 0 to 100](https://www.youtube.com/watch?v=Dtr3rR04ekE)

#### Storage

- [Five Greate Ways to Lose Data on Kubernetes (And How to Avoid Them)](https://www.youtube.com/watch?v=zW7gLyPln3w)
- [Intro to Rook: Storage for Kubernetes](https://www.youtube.com/watch?v=dA29dIK6g5o)
- [Speed Racer: Local Persistent Volumes in Production](https://www.youtube.com/watch?v=6RjjtSpLar0)
- [Intro to Longhorn: Open Source Cloud-Native Storage for K8s](https://www.youtube.com/watch?v=zJY2uxLtwUk)
- [Performance Optimization - Rook on Kubernetes](https://www.youtube.com/watch?v=v1u6bPM4SQU)
- [Rook Deep Dive: Ceph](https://www.youtube.com/watch?v=eTSokJ3-c-A)
- [OpenEBS 101: Hyperconverged Kubernetes Native Storage](https://www.youtube.com/watch?v=ELqukg4HrPg)

### Machine Learning & Big Data

- [From Notebook to Kubeflow Pipelines with HP Tuning: A Data Science Journey](https://www.youtube.com/watch?v=QK0NxhyADpM)
- [Enabling Multi-user Machine Learning Workflow for Kubeflow Pipelines](https://www.youtube.com/watch?v=U8yWOKOhzes)
- [Production Multi-Node Jobs with Gang Scheduling, K8S, GPUs and RDMA](https://www.youtube.com/watch?v=nXG8rPJrjzs)
- [Taming Data/State Challenges for ML Applications and Kubeflow](https://www.youtube.com/watch?v=fPpcodldlVg)
- [Reimagining the Worldwide LHC Computing Grid on Kubernetes](https://www.youtube.com/watch?v=NX6U9U8ZTl8)
- [Lesson Learned on Running Hadoop on Kubernetes](https://www.youtube.com/watch?v=Fht0Nj8GqIs)
- [How Kubeflow and MLOps Can Help Secure Your ML Workloads](https://www.youtube.com/watch?v=2sDi7Z2cW_A)
- [Is There a Place for Distributed Storage for AI/ML on Kubernetes?](https://www.youtube.com/watch?v=9XhbXtPKttM)
- [Monitoring GPUs at Scale for AI/ML and HPC Clusters](https://www.youtube.com/watch?v=X5gn_bgxJiw)
- [Expanding Serverless to Scale-out Kubeflow Pipelines](https://www.youtube.com/watch?v=CNpbfXnENk4)
- [Kubeflow 1.0 Update by a Kubeflow Community Product Manager](https://www.youtube.com/watch?v=99sA0KXmF7A)
- [SpoK - Running Big Data Application @ Sclae on K8s](https://www.youtube.com/watch?v=7ds0ad-EB2M)
- [Is Sharing GPU to Multiple Containers Feasible?](https://www.youtube.com/watch?v=MDkltK5JLCU)
- [Elephant on Wheels: Petabyte-scale AI @ LinkedIn](https://www.youtube.com/watch?v=VFIwJrkFw1s)
- [Introduction to Strimzi: Apache Kafka on Kubernetes](https://www.youtube.com/watch?v=GSh9aHvdZco)
- [How to Use Kubernetes to Build a Data Lake for AI Workloads](https://www.youtube.com/watch?v=0HIelZ3qMLE)
- [MLPerf Meets Kubernetes](https://www.youtube.com/watch?v=ZCffCr73-Zk)

### CNCF Projects

- [Tutorial: Builiding Secure & Decentralized Global Application on Kubernetes with NATS](https://www.youtube.com/watch?v=kN-GbWRVFos)
- [Notary v2 introduction and Status Report](https://www.youtube.com/watch?v=8K4a7Ltk_4U)
- [Zero Downtime Data Relocation with Vitess](https://www.youtube.com/watch?v=6--4bQKMNF4)
- [Vitess Intro: How to Migrate a MySQL Database to Vitess](https://www.youtube.com/watch?v=WRNftOqRVVY)
- [Easy, Secure and Fast - Using NATS for Data Streams and Services](https://www.youtube.com/watch?v=-IuFNF7D4AE)
- [Intro to gRPC](https://www.youtube.com/watch?v=n03sULIafeo)
- [gRPC Easy](https://www.youtube.com/watch?v=4PWVCI-m6Gw)
- [Intro:L Brigade](https://www.youtube.com/watch?v=SL2EIXLZjmw)

### Database

- [TiKV: A cloud Native Key-Value Database](https://www.youtube.com/watch?v=1B4riWTTAZg)
- [Serving Trillion-Record Table on TiKV](https://www.youtube.com/watch?v=TcxtkWjSo44)

### Others

- [Be a Good Corporate Citizen in Kubernetes](https://www.youtube.com/watch?v=3johr2CCeZw)
- [Kubernetes as a General Purpose Control Plane: Scaling on Kubernetes](https://www.youtube.com/watch?v=KEQCyXZ8jm4)
- [Kubernetes? But I'm a Product Manager](https://www.youtube.com/watch?v=Jes-xq7ZEpo)
- [Tutorial: Communication is key -- Understanding Kubernetes Networking](https://www.youtube.com/watch?v=InZVNuKY5GY)
- [Developing the Kubernetes Python Client](https://www.youtube.com/watch?v=HRN3mWymA34)
- [Stratup Containers in Ligtning Speed with Lazy Image Distribution](https://www.youtube.com/watch?v=H4Lbi26CqNU)
- [Sharing is Caring! Push Your Cloud Application to an OCI Registry](https://www.youtube.com/watch?v=MIAJaAr3gCk)
- [Zero Database Downtime with etcd operator](https://www.youtube.com/watch?v=Za9RkS42nbU)
- [Going Beyond CI/CD with Prow](https://www.youtube.com/watch?v=qQvoImxHydk)
- [Progressive Delivery in Kubernetes](https://www.youtube.com/watch?v=Jf29YXu1Q48)
- [Go? Bash! Meet the Shell-operator](https://www.youtube.com/watch?v=we0s4ETUBLc)
- [Banking on Kubernetes the Hard Way in Production](https://www.youtube.com/watch?v=Rf1sGlpdvmA)
- [Toolchains Behind Successful Kubernetes Development Workflow](https://www.youtube.com/watch?v=4YanEWCAPlk)
- [KubeBirt Intro - Using KubeVirt to Run VMs at Scale](https://www.youtube.com/watch?v=zLQA-YUQg1k)
- [The Past, Presentm, and Future of Cloud Native API Gateway](https://www.youtube.com/watch?v=1mBp8uxImO8)
- [The Hidden Generics in Kubernetes API](https://www.youtube.com/watch?v=JmwnRcc2m2A)
- [The Kubernetes Effect - Igniting Transormation in Your Team](https://www.youtube.com/watch?v=EuZPwAjUWjc)
- [Look Ma, No Pause!](https://www.youtube.com/watch?v=NObGcCJZgws)
- [ComponentConfig Technical Challenges](https://www.youtube.com/watch?v=8azcZdKFamc)
- [Using Kubernetes Secrets in GitOps Workflows Securely](https://www.youtube.com/watch?v=-k6HEXaE75k)
- [Building Software-Defined-Network using K8s API Machinery and Controllers](https://www.youtube.com/watch?v=WX-8Of8AQuw)
- [OpenID Connect as SSO Solution: Strengths and Weaknesses](https://www.youtube.com/watch?v=Ezi7LkpaU6Q)
- [Hands-On Intro to Cloud-Native CI/CD with Tekton](https://www.youtube.com/watch?v=CnVCgMRE4xI)
- [Kubernetes Leader Election for fun and Profit](https://www.youtube.com/watch?v=WslJyYb81w8)
- [A Journey Through Kubernetes Admission Controller Taxanomy](https://www.youtube.com/watch?v=rPLH1aTeJ5Q)
- [Optimized Resource Allocation in Kubernetes? Topology Manager is Here](https://www.youtube.com/watch?v=KU_EtejzXp0)
- [Introduction to Windows Containers in Kubernetes](https://www.youtube.com/watch?v=tUAax3aIapE)
- [Architectural Caching Patterns for Kubernetes](https://www.youtube.com/watch?v=poO6KDRHAL0)
- [Effective Kubernetes Onboarding](https://www.youtube.com/watch?v=1sfoYf3TbQk)
- [We migrated our Monolith to K8s and Became a High Perfoming Team](https://www.youtube.com/watch?v=RbGy4oK_0qw)
- [Escaping the Jungle - Migration to Cloud Native CI/CD](https://www.youtube.com/watch?v=kgVe5cWSMZQ)
- [Controllers at Chaos](https://www.youtube.com/watch?v=kQT82Qx97L4)

### Edge

- [34 Truths We Learned About Kubernetes and Edge](https://www.youtube.com/watch?v=2Eqg-oKRIR8)
- [KubeEdge: Kubernetes Native Edge Computing Framework](https://www.youtube.com/watch?v=Y6StZUBABdk)
- [KubeEdge Hands on Workshop - Build Your Edge AI App on Real Edge Devices](https://www.youtube.com/watch?v=OkenX0U2y08)

### Managing & Debugging the cluster

- [etcd Watchers Not Working? Improving Error Handling in Your Application](https://www.youtube.com/watch?v=ftfZli-BvJ8)
- [Stayin' Alive: PodDistrustipnBudgets for Maintenance and Upgrades](https://www.youtube.com/watch?v=0AGZ5no6-yo)
- [From Alert Notification to Comparison of Good and Bad Requests in One Click](https://www.youtube.com/watch?v=nsTEFLwRJRI)
- [Deep-Dive: Packet-level Debugging of Bridged and Non-bridged CNI Plugins](https://www.youtube.com/watch?v=RQNy1PHd5_A)
- [Kubernetes DNS Horror Stories (And How to Avoid Them)](https://www.youtube.com/watch?v=Yq-SVNa_W5E)
- [Help! Please Resue Not-ready Nodes Immediately](https://www.youtube.com/watch?v=7obeauqry_U)
- [20,000 Upgrades Later: Lessons From a Year of Managed Kubernetes Upgrades](https://www.youtube.com/watch?v=apt8FUhrJiw)
- [Observing Kubernetes Without Losing Your Mind](https://www.youtube.com/watch?v=gt4wj3DBz6g)
- [Managing a Managed Kubernetes Platform](https://www.youtube.com/watch?v=TBydMGkWykQ)
- [Improving the Performance of Your Kubernetes Cluster](https://www.youtube.com/watch?v=tvreJem3xIw)
- [In-place Upgrade Noway! Blue/Green Your Way to a New Kubernetes Version](https://www.youtube.com/watch?v=UFanjXXOsVA)
- [Where to Put All That YAML: Secure Content Management for Cloud Native Apps](https://www.youtube.com/watch?v=sVyng761IXM)
- [Where's My Container? Visualizing the GitOps Container Journey at Microsoft](https://www.youtube.com/watch?v=JfQvAtsZP7Y)
- [Nondestructive Forensics: Debugging K8s Services Without Disturbing State](https://www.youtube.com/watch?v=fMtJFtKeENA)

### Multi-Cloud

- [Hacking on Network Service Mesh Dataplane for a True Multi-cloud Experience](https://www.youtube.com/watch?v=zzDAAMC7214)
- [Managing Multi-Cluster/Multi-Tenant Kubernetes with GitOps](https://www.youtube.com/watch?v=yjflWxZaHY4)
- [CoreDNS for Hybrid and Multi-Cloud](https://www.youtube.com/watch?v=7ZQgIECUEwg)
- [Design Choices Behind Making gRPC Available on Web Platforms](https://www.youtube.com/watch?v=JtdIouJaDIE)
- [Multi-cluster Made Reasonable: Envoy Service Mesh Control Plane](https://www.youtube.com/watch?v=7aMgS1uRU5s)

### Bare Metal

- [Network Isolation and Security Policies for Kubernetes Bare-metal Nodes](https://www.youtube.com/watch?v=AjEgSUN1aYw)
- [Failure Stories From the Onpremise Bare-metal World](https://www.youtube.com/watch?v=pmuzOWB64Sg)
