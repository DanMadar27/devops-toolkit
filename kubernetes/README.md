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

## kubectl Commands Reference

### Pod Management
```bash
kubectl get pods                    # List pods in current namespace
kubectl get pods -A                 # List pods in ALL namespaces. -A can be used in more commands.
kubectl get pods -o wide            # List pods with extra info (node, IP)
kubectl describe pod <pod-name>     # Detailed info about a pod
kubectl logs <pod-name>             # View pod logs
kubectl logs -f <pod-name>          # Stream pod logs
kubectl exec -it <pod-name> -- sh   # Shell into a pod
kubectl delete pod <pod-name>       # Delete a pod
```

### Deployments
```bash
kubectl get deployments
kubectl create deployment <name> --image=<image>
kubectl scale deployment <name> --replicas=3
kubectl rollout status deployment/<name>
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name>
kubectl set image deployment/<name> <container>=<new-image>
```

### Services & Networking
```bash
kubectl get svc                          # List services
kubectl expose deployment <name> --port=80
kubectl port-forward <pod-name> 8080:80  # Forward local port to pod
kubectl get ingress
```

### Namespaces
```bash
kubectl get namespaces
kubectl create namespace <name>
kubectl config set-context --current --namespace=<name>  # Switch namespace
```

### Config & Context
```bash
kubectl config get-contexts      # List all contexts
kubectl config use-context <ctx> # Switch context
kubectl config current-context   # Show current context
kubectl config view --minify | grep server # Check which server the kubeconfig is pointing to
kubectl cluster-info # Get info about current cluster

# Create new config by copy config directly to your laptop
scp user@master-node:/etc/kubernetes/admin.conf ~/.kube/config
```

### Nodes
```bash
kubectl get nodes
kubectl describe node <node-name>
kubectl cordon <node-name>    # Mark node unschedulable
kubectl drain <node-name>     # Evict pods from node
kubectl uncordon <node-name>  # Mark node schedulable again
```

### Apply / Manage Resources
```bash
kubectl apply -f <file.yaml>        # Apply a manifest
kubectl delete -f <file.yaml>       # Delete resources from manifest
kubectl get all                     # List all resources in namespace
kubectl get all -A                  # List all resources across namespaces
kubectl edit <resource> <name>      # Edit resource in-place
kubectl patch <resource> <name> ... # Patch a resource
```

### Debugging & Utilities
```bash
kubectl top pods                 # CPU/memory usage for pods
kubectl top nodes                # CPU/memory usage for nodes
kubectl get events               # Show cluster events
kubectl explain <resource>       # Docs for a resource type
kubectl api-resources            # List all available resource types
```

## Helm Commands Reference

### Repository Management
```bash
helm repo add <name> <url>        # Add a chart repository
helm repo list                    # List added repositories
helm repo update                  # Update all repo indexes
helm repo remove <name>           # Remove a repository
helm repo index <dir>             # Generate index file for a repo
```

### Search Charts
```bash
helm search repo <keyword>        # Search in added repos
helm search hub <keyword>         # Search on Artifact Hub
helm search repo <name> --versions  # Show all available versions
```

### Install & Deploy
```bash
helm install <release> <chart>                        # Install a chart
helm install <release> <chart> -n <namespace>         # Install in a namespace
helm install <release> <chart> --create-namespace     # Create namespace if not exists
helm install <release> <chart> -f values.yaml         # Install with custom values file
helm install <release> <chart> --set key=value        # Install with inline value override
helm install <release> <chart> --dry-run              # Simulate install (no changes)
helm install <release> <chart> --version 1.2.3        # Install specific version
```

### Upgrade
```bash
helm upgrade <release> <chart>                        # Upgrade a release
helm upgrade <release> <chart> -f values.yaml         # Upgrade with custom values
helm upgrade <release> <chart> --set key=value        # Upgrade with inline override
helm upgrade --install <release> <chart>              # Install if not exists, upgrade if does
helm upgrade <release> <chart> --atomic               # Rollback automatically on failure
helm upgrade <release> <chart> --dry-run              # Simulate upgrade
```

### Rollback
```bash
helm rollback <release>           # Rollback to previous version
helm rollback <release> 2         # Rollback to specific revision number
helm history <release>            # View revision history of a release
```

### Uninstall
```bash
helm uninstall <release>                    # Remove a release
helm uninstall <release> -n <namespace>     # Remove from specific namespace
helm uninstall <release> --keep-history     # Remove but keep history
```

### List & Status
```bash
helm list                         # List releases in current namespace
helm list -A                      # List releases in ALL namespaces
helm list -n <namespace>          # List releases in specific namespace
helm list --failed                # Show only failed releases
helm status <release>             # Show status of a release
```

### Inspect & Debug
```bash
helm show chart <chart>           # Show chart metadata
helm show values <chart>          # Show default values of a chart
helm show readme <chart>          # Show chart README
helm get values <release>         # Get values used in a deployed release
helm get manifest <release>       # Get rendered Kubernetes manifests
helm get all <release>            # Get all info about a release
helm template <release> <chart>   # Render templates locally without installing
helm lint <chart>                 # Lint a chart for errors
```

### Create & Package
```bash
helm create <name>                # Scaffold a new chart
helm package <chart-dir>          # Package chart into a .tgz file
helm dependency update <chart>    # Download/update chart dependencies
helm dependency list <chart>      # List chart dependencies
```

### Plugin Management
```bash
helm plugin list                  # List installed plugins
helm plugin install <url>         # Install a plugin
helm plugin uninstall <name>      # Remove a plugin
helm plugin update <name>         # Update a plugin
```

### Environment & Version
```bash
helm version                      # Show Helm version
helm env                          # Show Helm environment variables
```

---

### Most Used Combos

```bash
# Add a repo and install a chart in one flow
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install my-redis bitnami/redis -n myapp --create-namespace

# Upgrade or install (idempotent — safe to run repeatedly)
helm upgrade --install my-app ./my-chart -f values.yaml -n myapp --create-namespace

# Debug what will be deployed before applying
helm template my-app ./my-chart -f values.yaml | kubectl apply --dry-run=client -f -

# Check what values a live release is using
helm get values my-app -n myapp
```

---

### Key Flags Cheatsheet

| Flag | Meaning |
|---|---|
| `-n <namespace>` | Target namespace |
| `-A` | All namespaces |
| `-f values.yaml` | Custom values file |
| `--set key=val` | Inline value override |
| `--dry-run` | Simulate without applying |
| `--atomic` | Auto rollback on failure |
| `--create-namespace` | Create namespace if missing |
| `--version` | Pin to a specific chart version |
| `--install` | Install if release doesn't exist |