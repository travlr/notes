**Creating a Custom Cluster from Scratch**

# Designing and Preparing

## Cloud Provider
- is a module which provides an interface for managing:
  - tcp load balancers
  - nodes (instances)
  - networking routes

- is defined in `pkg/cloudprovider/cloud.go`
  - not necessarily needed (e.g. bare metal)
  - not all parts of the iface need be implemented
    - depends on how flags are set on various components

## Nodes
- virtual or physical machines
- 4 instances recommended, but can build with 1
- x86_64 linux
- apiserver and etcd on a machine with 1 core and 1gb ram for 10s of nodes will
  suffice
  - larger or more active clusters may benefit from more cores

- minion nodes can have
  - any reasonable amount of memory
  - any number of cores
  - do not need identical configurations

## Network

### Network Connectivity
- see the distinctive [Newtorking Model](https://goo.gl/Om7zSJ)
- allocates an IP address to each pod
- a block of IPs need to be allocated to the cluster for k8s to use as pod ips
- simply, allocate a different block of ips to each node as each node is added
- a process in one pod should be able to communicate with another pod using the
  ip of the second pod
- can be accomplished in two ways
  1. using an overlay network
    - obscures the underlying network architecture from the pod network
      - via encapsulation
      - adds some overhead

  2. without an overlay network
    - configure the underlying network fabric to be aware of ip addresses
      - switches
      - routers
      - etc
    - better performance (no encapsulation)

- choosing a method (above) depends on environment and requirements
- the above options can be achieved in various ways:
  - use a network plugin which is called by k8s
    - k8s supports the [CNI](https://goo.gl/Ux1ZjV) network plugin interface
    - e.g.. calico, flannel, weave or write your own

  - compile directly into k8s
    - implement the "Routes" interface of a cloud provider module
    - the [gce](https://goo.gl/uYQ4XQ) and [aws](https://goo.gl/a2nQQn) guides use this
      approach

  - configure network external to k8s
    - can be done by
      - manually running commands
      - through a set of externally maintained scripts

    - implemented yourself.. gives extra degree of flexibility

- select an address range for pod ips
  - no ipv6 yet
  - various approaches
    - gce: each project has its own 10.0.0.0/8
      - carve off a /16 for each k8s cluster
        - leaves room for several clusters

      - each node gets a subdivision of this space

    - aws: use one vpc for whole org
      - carve off for each cluster
      - or.. use different vpc for each cluster

  - allocate on cidr subnet
    - for each node's pod ips
    - or a single large cidr
      - smaller cidrs are automatically allocated to each node

    - need max-pods-per-node * max-number-of-nodes IPs in total
      - a /24 per node supports 254 pods per node.. is a common choice
      - if ips are scarce /26 per node (62 pods)
      - or even a /27 (30 pods)

    - e.g.
      - use 10.10.0.0/16 for cluster
        - <=256 nodes using 10.10.0.0/24 to 10.10.255.0/24

    - need to make these rout-able or connect with overlay

- k8s allocates an ip to each service
- service ips are not routed, necessarily
- kube-proxy translates service ips to pod ips
- services also require a block of ips allocated
  - SERVICE_CLUSTER_IP_RANGE="10.0.0.0/16" (65534 services)
  - can be appended to
  - can't be moved otherwise

- static ip needed for master node
  - MASTER_IP
  - open firewall for port 80 and/or 443
  - enable ipv4 forwarding sysctl
    - net.ipv4.ip_forward=1

### Network Policy
- fine-grained policy via [NetworkPolicy](https://goo.gl/okBTmh) resource
- not all networking providers support k8s NetworkPolicy api
  - see [Using NetworkPolicy](https://goo.gl/vyM3pP)

## Cluster Naming
- must be a unique name
- CLUSTER_NAME env var

## Software Binaries
- binaries needed for
  - etcd
  - docker or rkt
  - k8s
    - kubelet
    - kube-proxy
    - kube-apiserver
    - kube-controller-manager
    - kube-scheduler

### Downloading and Extracting Kubernetes Binaries
- k8s binary release includes all kube binaries as well as supported etcd
- see [Developer Documentation](https://goo.gl/rDME5D) for building from source
- [Lates Binary Release](https://goo.gl/rR2mxZ) link
  - or?? call `./kubernetes/cluster/get-kube-binaries.sh`
    - tar.gz dloaded to `./kubernetes/server/kubernetes-server-linux-amd64.tar.gz`
    - binaries in `./kubernetes/server/bin`

### Selecting Images
- docker, kubelet and kube-proxy run outside of a container
- etcd, kube-apiserver, kube-controller-manager and kube-scheduler should be run
  as containers
- images
  - google container registry (gcr)
    - e.g. gcr.io/google-contriners/hyperkube:$TAG
    - see [latest release page](https://goo.gl/rR2mxZ) for $TAG
      - use same tag as used for kubelet and kube-proxy

    - the hyperkube binary is an all-in-one binary
      - hyperkube kubelet
      - hyperkube apiserver

  - build your own
    - better for private registries
    - example `./kubernetes/server/bin/kube-apiserver.tar` can be converted using
      `docker load -i kube-apiserver`
    - can verify successful image loading with right repo and tag using
      `docker images`

  - for etcd..
    - use images on gcr.. `gcr.io/google-contriners/etcd:2.2.1`
    - dockerhub
    - quay.io
    - buil your own
      - `cd kubernetes/cluster/images/etcd; make`
    - RECOMENDED.. use version provides with k8s binary distribution
    - the $TAG is available in `kubernetes/cluster/images/etcd/Makefile`

  - env vars
    - HYPERKUBE_IMAGE=
    - ETCD_IMAGE=

## Security Models
1. Access the apiserver via HTTP
  - use a firewall for security
  - easier to setup

2. use HTTPS
  - use certs and credentials for user
  - recomended approach
  - configuring certs can be tricky

### Preparing Certs
- the master needs a cert to act as an HTTPS server
- the kubelets optionally need certs to
  - id themselves as clients to the master
  - when serving its own API over HTTPS

- use a CA or generate root cert and use that to sign into master, kubelet and
  kubectl certs.. see [authentication documentation](https://goo.gl/Aqdg6U)

- files
  - CA_CERT
    - put on node where apiserver runs.. e.g.
      - `/srv/kubernetes/ca.crt`

  - MASTER_CERT
    - signed by CA_CERT
    - put on node where apiserver runs .. e.g.
      - `/srv/kubernetes/server.crt`

  - MASTER_KEY
    - put on node where apiserver runs.. e.g.
      - `srv/kubernetes/server.key`

  - KUBELET_CERT
    - optional

  - KUBELET_KEY
    - optional

### Preparing Credentials
- the admin user and any users need
  - a token or password
  - tokens are 32 char strings
    - e.g.
      ```BASH
      TOKEN=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | \
      dd bs=32 count=1 2>/dev/null)
      ```

**TO BE CONTINUED**
