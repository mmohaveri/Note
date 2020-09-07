# Pod Networks and comparison of popular CNI plugins

Notes from [Comparing Kubernetes CNI Providers: Flannel, Calico, Canal, and Weave](https://rancher.com/blog/2019/2019-03-21-comparing-kubernetes-cni-providers-flannel-calico-canal-and-weave/)

## Introduction

**Container networking** is the mechanism through which containers can optionally connect to other containers, the host,
and outside networks like the internet. Container runtimes offer various networking modes. As an example docker provides
none, host, and bridge networking modes.

CNI, [Container Network Interface](https://github.com/containernetworking/cni), is a standard interface for programs to
dynamically configure networks and resources of a container. [It's spec](https://github.com/containernetworking/cni/blob/master/SPEC.md)
outlines a plugin interface for container runtimes to coordinate with plugins to configure networking.

Plugins are responsible for provisioning and managing an IP address to the interface and usually provide functionality
related to IP management, IP-per-container assignment, and multi-host connectivity.

The container runtime calls the networking plugins to allocate IP addresses and configure networking when the container
starts and calls it again when the container is deleted to clean up those resources.

The runtime decides on the network a container should join and the plugin that it needs to call. The plugin then adds
the interface into the container network namespace as one side of a *veth* pair. It then makes changes on the host machine,
 including wiring up the other part of the *veth* to a network bridge. Afterwards, it allocates an IP address and sets up
 routes by calling a separate IPAM (IP Address Management) plugin.

Kubernetes networking model demands [certain network features](https://kubernetes.io/docs/concepts/cluster-administration/networking#the-kubernetes-network-model).
In short it demands that:

- Each Pod gets its own IP address
- Pods on a node have the ability to communicate with all Pods on all nodes without NAT
- Agents on a node have the ability communicate with all pods on that node

CNI allows kubelet to automatically configure networking for the Pods by calling the plugins at appropriate times. These
plugins do the work of making sure that Kubernetes’ networking requirements are satisfied and providing the networking
features that cluster administrators require.

## Some network terminology

- **Layer 2 networking** or **data link layer** deals with delivery of frames between two adjacent nodes on a network,
  e.g. Ethernet.
- **Layer 3 networking** or **network layer** routes packets between hosts on top of the layer 2 connections, e.g. IPv4
  & IPv6.
- **Layer 4 networking** or **transport layer** is responsible for end-to-end communication over layer 3, e.g TCP & UDP,
  and provides additional services such as connection-oriented communication, reliability, flow control, multiplexing, etc.
- **Overlay network** is a virtual network built on top of an existing network. They are often used to provide useful
  abstractions on top of existing networks and to separate and secure different logical networks.
- **Encapsulation** is the process of wrapping network packets in an additional layer to provide additional context and
  information. In overlay networks, encapsulation is used to translate from the virtual network to the underlying address
  space to route to a different location.
- **VXLAN**, **virtual extensible LAN**, is an encapsulation and overlay protocol. It is used to help large cloud
  deployments scale by encapsulating layer 2 Ethernet frames within UDP datagrams. It’s a *VLAN* extension that offers more
  flexibility and power.
- **Mesh Network** is a network in which each node connects to many other nodes, to cooperate on routing and achieve
  greater connectivity. Network meshes provide more reliable networking by allowing routing through multiple paths. The
  downside of a network mesh is that each additional node can add significant overhead.
- **BGP**, **border gateway protocol**, is a protocol to manage how packets are routed between edge routers. It helps
  figure out how to send a packet from one network to another by taking into account available paths, routing rules, and
  specific network policies. BGP is sometimes used as the routing mechanism in CNI plugins instead of encapsulated overlay
  networks.
- **IPVS**, **IP Virtual Server**, is a layer 4 load balancer implemented as part of the linux kernel. It can direct
  requests for TCP/UDP-based services to the real servers, making services of the real servers appear as virtual services
  on a single IP address.
- **iptables** is a linux utility program that allows configuration of  the IP packet filter rules of the Linux kernel firewall.

## Different CNI options

When it’s time to choose a CNI plugin, you have many options to choose from, some of the more popular options are Calico,
Flannel, Canal, Weave, and Kube Router.
In the following segments we’ll try to compare these options and help you to choose more wisely.

### [Flannel (5.6k ⭐)](https://github.com/coreos/flannel)

Developed by CoreOS, Flannel is one of the most mature and most popular CNI plugins available, intended to allow for better
inter-container and inter-host networking. It is packaged as a single binary called flanneld, and uses the cluster’s
existing etcd to store its state information.

Flannel configures a layer 3 IPv4 overlay network. A large internal network is created that spans across every node within
the cluster. Within this overlay network, each node is given a subnet to allocate IP addresses internally. As pods are
provisioned, the Docker bridge interface on each node allocates an address for each new container.

Pods within the same host can communicate using the Docker bridge, while pods on different hosts will have their traffic
encapsulated in UDP packets by flanneld for routing to the appropriate destination. For this reason, you’ll need to run
flanneld on all your nodes.

Flannel has several different types of backends available for encapsulation and routing. The default and recommended
approach is to use VXLAN, as it offers both good performance and is less manual intervention than other options.
Flannel has two major limitations, lack of support for multiple networks and
[network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/). The latter can be
overcame by utilizing Canal.

Overall, Flannel is a good choice for most users. From an administrative perspective, it offers a simple networking model
that sets up an environment that’s suitable for most use cases when you only need the basics. In general, it’s a safe bet
to start out with Flannel until you need something that it cannot provide.

### [Calico (1.9k ⭐)](https://github.com/projectcalico/calico)

Calico is another popular networking option best known for its performance, flexibility, and power. Calico concerns
itself not only with providing network connectivity between hosts and pods, but also with network security and administration.
The [Calico CNI plugin](https://github.com/projectcalico/cni-plugin) wraps Calico functionality within the CNI framework.

On a freshly provisioned Kubernetes cluster, that has Calico’s
[system requirements](https://docs.projectcalico.org/getting-started/kubernetes/requirements), Calico can be deployed
quickly by applying a single manifest file. If you are interested in Calico’s optional network policy capabilities, you
can enable them by applying an additional manifest to your cluster.

Calico uses BGP to configure the layer 3 network to route packets between hosts. This means that packets do not need to
be wrapped in an extra layer of encapsulation when moving between hosts. Besides the performance improvements, this
approach allows for more conventional troubleshooting when network problems arise.

Calico also provides some advanced network features, like
[Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/), Istio integration, etc. Its
Istio integration interprets and enforces policy for workloads within the cluster both at the service mesh layer and the
network infrastructure layer.

Calico is a good choice when performance and features like network policy are important. It’s especially a good choice
when you want to be able to control your network instead of just configuring it once and forgetting about it.

### Canal

Canal is combining Calico and Flannel together. It’s the intersection of the two projects and tries to achieve the best
of both worlds. The networking layer is the simple overlay network provided by Flannel. The network policy capabilities
are provided by Calico’s powerful networking rule evaluation to provide additional security and control.

### [Weave Net (5.9k ⭐)](https://github.com/weaveworks/weave)

Weave Net is another CNI-capable networking option for Kubernetes that creates a full mesh overlay network between the
nodes of a cluster, allowing for flexible routing between participants.

Weave relies on a routing component installed on all hosts. These components, routers, exchange topology information to
maintain an up-to-date view of the available network landscape. When looking to send traffic to a pod on a different node,
the router choose between sending via “fast datapath” or falling back on the “sleeve” packet forwarding method.

Fast datapath is an approach that relies on the kernel’s native Open vSwitch datapath module to forward packets to the
appropriate pod without moving in and out of user space multiple times. The Weave router updates the Open vSwitch
configuration to ensure that the kernel layer has accurate information about how to route incoming packets.

Sleeve mode is a backup option for the times that networking topology isn’t suitable for fast datapath routing. It’s an
encapsulation mode that can route packets in instances where fast datapath does not have the necessary routing information
or connectivity.

As traffic flows through the routers, they learn which peers are associated with which MAC addresses, allowing them to
route more intelligently with fewer hops for subsequent traffic.

Weave also provides network policy capabilities. It also provides an easy way to encrypt your network traffic, using
NaCl (salt) for sleeve traffic, and IPSec for fast datapath traffic.

Weave is a great option for those looking for feature rich networking without adding a large amount of complexity or
management. It is relatively easy to set up, offers many built-in and automatically configured features, and can provide
routing in scenarios where other solutions might fail, although the mesh topography may cause performance problems in
large networks.

### [Kube Router (1.5k ⭐)](https://github.com/cloudnativelabs/kube-router)

Kube-router is a Layer 3 CNI plugin for Kubernetes aiming to provide operational simplicity and high performance.
It uses BGP for L3 networking, iptables for network policies and IPVS for Kube Services Proxy (if setup to replace kube-proxy).

One of the key design tenets of Kube-router is to use standard Linux networking stack and tool set. There are no overlay
networks, just plain good old Linux networking. It will result in a lightweight all-in-one solution with a small footprint.

It also does not have any dependency on a data store and does not implement any custom solution for pod CIDR allocation
to the nodes and uses standard CNI plugins so does require any additional CNI plugin.

With all features enabled, kube-router is a lean yet powerful alternative to several network components used in typical
Kubernetes clusters.

### [Multus (810 ⭐)](https://github.com/intel/multus-cni)

Multus is a CNI plugin that provides multiple network interface support to pods. For each interface Multus delegates CNI
calls to secondary CNI plugins.

## Ease of installation and performance comparison

Based on [this article](https://itnext.io/benchmark-results-of-kubernetes-network-plugins-cni-over-10gbit-s-network-36475925a560),
the easiest CNI to install is Flannel. It’s also one of the most performant ones, with high performance in all categories
(TCP, UDP, HTTP, etc.) and low resource consumption.

If you need to support Network Policies, you can use Canal (if you already have a cluster running with Flannel) or Calico.
Just keep in mind that both Calico and Canal need manual MTU selection, as they don’t find the best MTU possible
automatically.