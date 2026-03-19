# Kubernetes

Links:

- [K8s Tutorials](https://kubernetes.io/docs/tutorials/)
- [K8s Concepts](https://kubernetes.io/docs/concepts/)
- [K8s Cluster Architecture](https://kubernetes.io/docs/concepts/architecture/)
- [Workload Management](https://kubernetes.io/docs/concepts/workloads/controllers/)
- [Services For Communication](https://kubernetes.io/docs/concepts/services-networking/)
- [Storage](https://kubernetes.io/docs/concepts/storage/)
- [Configuration](https://kubernetes.io/docs/concepts/configuration/)

## K8s Cluster Architecture

A Kubernetes cluster consists of a control plane plus a set of worker machines, called nodes,that run containerized applications. Every cluster needs at least one worker node in order to run Pods.

### Control plane

The Control Plane's is responsible for managing the cluster. The Control Plane coordinates all activities in your cluster, such as scheduling applications, maintaining applications' desired state, scaling applications, and rolling out new updates.

The control plane's components are:

- **kube-apiserver:** component of the Kubernetes control plane that exposes the Kubernetes API.The API server is the front end for the Kubernetes control plane.

- **etcd**: Consistent and highly-available key value store used as Kubernetes' backing store for all cluster data.

- **kube-scheduler**: component that watches for newly created Pods with no assigned node, and selects a node for them to run on.

- **kube-controller-manager**: component that runs controller processes such as:
    - **Node controller:** Responsible for noticing and responding when nodes go down.
    - **Job controller:** Watches for Job objects that represent one-off tasks, then creates Pods to run those tasks to completion.
    - **EndpointSlice controller**: Populates EndpointSlice objects (to provide a link between Services and Pods).
    - **ServiceAccount controller**: Create default ServiceAccounts for new namespaces.

- **cloud-controller-manager:** component that embeds cloud-specific control logic. The cloud controller manager lets you link your cluster into your cloud provider's API, and separates out the components that interact with that cloud platform from components that only interact with your cluster. In on-premises or in learning environments this component not exist in the cluster.

### Nodes

A node is a VM or a physical computer that serves as a worker machine in a Kubernetes cluster.
The node's components are:

- **kubelet:** makes sure that containers are running in a Pod.

- **kube-proxy (optional)**: maintains network rules on nodes that allow network communication to the Pods

- **Container runtime**: A fundamental component that empowers Kubernetes to run containers effectively

#### Pods

Pods are the smallest deployable units of computing that you can create and manage in Kubernetes.

A Pod (as in a pod of whales or pea pod) is a group of one or more containers, with shared storage and network resources, and a specification for how to run the containers.

### Communication

Node-level components, such as the kubelet, communicate with the control plane using the Kubernetes API,which the control plane exposes. End users can also use the Kubernetes API directly to interact with the cluster.

### Addons

Addons use Kubernetes resources (DaemonSet,Deployment, etc) to implement cluster features such as:

- **DNS:** serves DNS records for Kubernetes services

- **Web UI (Dashboard):** allows users to manage and troubleshoot applications running in the cluster, as well as the cluster itself.

- **Container resource monitoring:** records generic time-series metrics about containers in a central database, and provides a UI for browsing that data.

- **Cluster-level Logging:** responsible for saving container logs to a central log store with a search/browsing interface.

- **Network plugins:** responsible for allocating IP addresses to pods and enabling them to communicate with each other within the cluster.

