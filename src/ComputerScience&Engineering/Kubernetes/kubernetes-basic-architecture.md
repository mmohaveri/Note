# Kubernetes Basic Architecture

Notes from [Inside Kubernetes: An Architectural Deep Dive with Anthony Nocentio](https://youtu.be/d5Rmu3fboiQ?t=300)

## What is Kubernetes?

- A Container Orchestrator

## Benefits of Kubernetes

- Managing (desired) state, starting things and keeping them up.
  - Ability to absorb change quickly
  - Ability to recover quickly
  - Speed and consistency of deployment
- Infrastructure Abstraction
  - Hide complexity in cluster
  - Ability to upscale and downscale easily
- Persistent application access endpoint

## Kubernetes API Objects

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

## Kubernetes Architecture

### Master

Runs a couple of services

- API Server: Main Communication hub (stateless)
- Cluster Store: Persist the state of deployments
  - Implemented by etcd key-value store
- Scheduler: Figures out where to run Pods in the cluster
- Controller manager: Implements controllers (the things that make sure the cluster stays in the desired state)

### Kubectl

The tool that we use to interact with API server

### Nodes

The thing that does the actual work, runs Pods, etc.

- Kubelet
  - Monitor API server (pooling) for changes in state and works assigned to the node.
- Kube Proxy
  - Implements network services
    - Generally iptables, exposes everything that’s running inside applications on an node onto the network
- Container runtime
  - Conventionally docker, but can be anything that supports an specific API
  - Pulls the containers off the registry and run them inside the node

By default master **won’t run** user workloads (is tainted from scheduling). Master components are deployed as Pods as
well but they’ll start in a special way and will always run on the master.

You can change this, but in a production environment you **SHOULD NOT**.

## Deploying Applications

Kubernetes uses a declarative approach to deployments. You describe your desired state in a YAML or json manifest.

### Deploying Applications Process

1. **Kubectl** submits a YAML to kubernetes (kubectl apply -f replicaset-manifest.yaml)
2. **API Server** authenticates the request
3. **API Server** authorizes whether the user has the authority to do the thing it wants to do (creating a ReplicaSet
   and pods) or not based on the Role Based Security (RBAC).
4. If everything is ok, **API Server** stores the manifest inside the **Cluster Store**.
5. **Scheduler** and **Controller Manager** are watching changes on **Cluster Store**.
6. After getting the notification from **Cluster Store**, ReplicaSet controller reads changes and creates needed Pods
   for the ReplicaSet by storing needed Pod definitions into **Cluster Store**.
7. After getting notification from **Cluster Store** (about the unscheduled Pods), **Scheduler** figures out
   (based on required and available resources) on what node the Pods should run and writes this information back to
   **Cluster Store**.
8. **Kubelet** is pooling the **API Server** about any work, and gets back with the list of Pods that it’s supposed to run.
9. **Kubelet** informs **Container Runtime** to download and run the needed containers.
10. **Kubelet** informs **KubeProxy** about needed services and it implements them.

## Building Production Ready Clusters

- Scalability (enough resources Nodes)
- Inter-cluster communication (Full mesh networking, all things needed for our applications and our nodes to communicate
  to each other in a Highly Available fashion).
- High Availability resources
  - API Server (Load Balanced)
  - Cluster Store, etcd (Multiple Replicas)
- Disaster Recovery
  - etcd Backup
- Persistent Volumes
