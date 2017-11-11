# Self-Hosted Kubernetes

[KubeCeption! A Story of Self-Hosted Kubernetes by Aaron Levy, CoreOS, Inc.](https://www.youtube.com/watch?v=EbNxGK9MwN4)

- Kube manages its own components
- Core comps deployed as native api objs
  - objs:
    - controller
    - scheduler
    - api-server
    - proxy
  - secrets
    - api-server
    - controller
  - modeled as deployments, daemon-sets, secrets etc
  - means..
    - they are "stacked" on the kublet
    - its not needed to configure them on the host itself

![minimal self-host][img01]

- why self-hosting
  - containers are ideal
  - vastly simplifies bootstrapping nodes
  - vastly simplifies kube lifecycle mgmt

- simplify node bootstrap (requirements for a kube node)
  - for all nodes including masters
    - kubelet
    - container runtime (docker)
    - kube-config (enough info to reach api server)
  - minimal and universal on-host config
  - use your favorite tools for adding compute (instances)
    - provisioning very simple compute infrastructure and throwing kubernetes
      at it
  - let kubernetes manage the rest

- host requirements
  - example CoreOS
    - kublet.service
    - kubeconfig

- Any distro node bootstrap
  1. install kublet
    - ` $ ${pkgmanager} install kubelet`
  2. install container runtime
    - `$ ${pkgmanager} install docker`
  3. write kubeconfig (from dev machine)
    - `$ scp kubeconfig user@host:/etc/kubernetes/kubeconfig`
  4. start kubelet
    - `$ systemctl start kubelet`
  5. for master node only:
    - a master is a node with certain components running on that host
      - for self-hosting this comes for free with kube configuration
      - `$ kubectl label node n1 master=true`
        - OR have kubetlet start as a master:
          - `--node-labels=master=true`

- Simplify kubernetes lifecycle management
  - kubernetes is excellent at managing software
  - minimizes writing external software that manages kubernetes
    - external sw inevitably end up with less portable & more fragile
      solutions
    - instead, tools should stand on the shoulders of kubernetes
      - advantages e.g: application rolling-updates
      - upgrading the cluster itself:
        - `$ kubectl apply -f kube-apiserver.yml`
        - `$ kubectl apply -f kube-scheduler.yml`
        - `$ kubectl apply -f kube-controller-manager.yml`
        - `$ kubectl apply -f kube-proxy.yml`
      - the prev four commands WILL be all that is needed for rolling-update
        the kube cluster, but its not quite there yet (Nov 2016 ~v1.4.4)
        - daemon-sets don't yet support rolling-updates
        - EDIT... rolling-updates supported for daemon-sets as of v1.6
  - upstream improvements in k8s directly translate to improvements in
    managing kubernetes.
  - expertise managing software in kubernetes directly translates to
    managing kubernetes

- Demo.. rolling-update kube cluster
  1. make sure one (other?) node is labeled as a master (HA kube controll
     plane)
    - `$ kubectl label node xxx.xx.x.xxx master=true`
    - automatically creates second instance of api-server (because its a
      daemon-set)
  2. replicate kube-scheduler
    - `$ kubectl scale deployment/kube-scheduler --replicas=2 -n kube-system`
  3. replicate kube-controller-manager
    - `$ kubectl scale deployment/kube-controller-manager --replicas=2 -n
         kube-system`
  4. Change the image version in the manifest yml file:
    - `$ kubectl edit daemonset/kube-apiserver -n kube-system`
    - `$ kubectl edit deployment/kube-controller-manager -n kube-system`

- how it works
  - launching a self-hosted cluster
    - need an initial control plane to bootstrap a self-hosted cluster
      - [bootkube](github.com/kubernetes-incubator/bootkube)
        - acts as a temporary control plane long enough to be replaced by a
          self-hosted control plane
        - run only on the first node, then not needed again
        - is a single binary that includes an api-server, scheduler and
          control-manager
        - how it works:
          - assumptions
            - etcd (could be in bootkube by now ?? )
              - is available somewhere (it is network addressable)
            - kubelet is on a node
          1. start bootkube
            - tell bootkube where etcd lives (network address)
            - full-fledged control-plane is now active
          2. kubelet now has the ability to connect to the api-server
          3. issue command that creates
            - deployments
            - daemon-sets
            - services
            - secrets
          4. kubelet schedules the pods
            - the new control-plane is active but unusable as of yet
            - bootkube monitors this process and waits for READY state
          5. at READY state bootkube is terminated
          6. new control-plane is connected to etcd
          7. kubelet connects to api-server
          8. self-hosting complete

  - self-hosted components
    - minimal.. control-plane & proxy
      - api-server (daemon-set)
      - scheduler & controller-manager (deployments)
      - kube-proxy (daemon-set)
      - tls certs and service account keys (secrets)
    - can be self-hosted too..
      - kubelet
      - pod network
        - kubelet will periodically check for CNI config
        - until CNI is configured, only host network pods will be started
        - `$ kubectl create -f pod-network-daemonset`
      - etcd
        - https://coreos.com/blog/introducing-the-etcd-operator.html
        - https://github.com/coreos/etcd-operator
        - Is probably in bootkube by now (see bootkube)

  - disaster recovery
    - node failure in HA deployments
      - kubernetes should take care of this for us
      - pods re-scheduled to available nodes
    - partial loss of control-plane components
      - loss of all schedulers and/or controller-managers
      - need a scheduler to schedule the schedulers
      - recovery can be done with kubectl commands
        - see video at ~35:00
      - recovery is manually scheduling a single-copy pod
    - power cycling the entire control-plane
      - need to recover existing state in absence of api-server
      - "user-space" checkpointing:
        - https://github.com/kubernetes-incubator/bootkube/tree/master/cmd/checkpoint
      - kubelet pod checkpointing (or something)
        - https:/github.com/kubernetes/kubernetes/issues/489
    - permanent loss of control-plane
      - similar situation to initial node bootstrap, but utilizing existing etcd state or etcd backup
        - etcd should be backed up (by admin ??? )
      - need to start temp replacement api-server
        - could be binary, static pod, new tool, bootkube, etc
      - recovery once etcd+api is available can be done via kubectl

- todo (might be already done after Nov 2016)
  - daemonset rolling updagittes (DONE)
  - pod checkpointing (or something): kubernetes/issues/489
  - self-host etcd: bootkube/issues/31
  - build simple disaster recovery tooling





  [img01]: ./images/Screenshot_20171031_085039.png
