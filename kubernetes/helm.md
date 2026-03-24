# Helm

Helm is the **package manager for Kubernetes** — the same way `apt` manages packages on Ubuntu or `npm` manages packages in Node.js, Helm manages Kubernetes applications.

---

## The Problem Helm Solves

Deploying even a simple app on Kubernetes requires multiple YAML files:

```
deployment.yaml
service.yaml
ingress.yaml
configmap.yaml
secret.yaml
serviceaccount.yaml
...
```

Without Helm this means:
- Managing dozens of raw YAML files manually
- Copy-pasting and editing files for each environment (dev, staging, prod)
- No easy way to version, rollback, or share your setup
- Repetitive and error-prone configuration

---

## How Helm Fixes This

Helm bundles all those Kubernetes manifests into a single unit called a **Chart**. A chart is a reusable, versioned, and shareable package.

```
my-app/
├── Chart.yaml         # Chart metadata (name, version, description)
├── values.yaml        # Default configuration values
└── templates/         # Kubernetes YAML templates
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

Instead of applying 6 files manually, you just run:

```bash
helm install my-app ./my-app -f values-prod.yaml
```

---

## Core Purposes of Helm

### 1. 📦 Packaging
Bundle your entire application — all Kubernetes resources — into one portable chart that can be shared and reused across teams.

### 2. ⚙️ Templating
Use variables and logic inside your YAML files so the same chart works across different environments by just changing values:

```yaml
# templates/deployment.yaml
replicas: {{ .Values.replicaCount }}
image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
```

```yaml
# values-dev.yaml        # values-prod.yaml
replicaCount: 1          replicaCount: 5
image:                   image:
  tag: latest              tag: v2.3.1
```

### 3. 🔄 Release Management
Helm tracks every install and upgrade as a **revision**, giving you a full history and one-command rollback:

```bash
helm history my-app
helm rollback my-app 2    # roll back to revision 2
```

### 4. 🌍 Sharing via Repositories
Publish charts to a Helm repository (like Artifact Hub) so anyone can install your app with a single command — just like `npm install`:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-redis bitnami/redis
```

### 5. 🔁 Idempotent Deployments
The `upgrade --install` pattern means the same command works whether the app exists or not — perfect for CI/CD pipelines:

```bash
helm upgrade --install my-app ./chart -f values.yaml
```

---

## Helm vs Raw kubectl

| | Raw kubectl | Helm |
|---|---|---|
| Deploy app | Apply 6+ YAML files | One command |
| Manage environments | Duplicate YAML files | One chart, multiple value files |
| Rollback | Manual, complex | `helm rollback` |
| Share with team | Share raw YAMLs | Push chart to repo |
| Track history | No built-in tracking | Full revision history |
| Upgrade | Re-apply all files | `helm upgrade` |

---

## Where Helm Fits in the Ecosystem

```
Developer  →  Helm Chart  →  Helm Install  →  Kubernetes API  →  Running App
               (package)      (deploys)         (schedules)
```

Helm sits between you and Kubernetes — it translates your high-level intent ("deploy my app with these settings") into the raw Kubernetes objects the cluster needs.

---

## In Short

> Helm turns complex, multi-file Kubernetes deployments into simple, versioned, repeatable one-liners — making it essential for any team running applications on Kubernetes at scale.

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