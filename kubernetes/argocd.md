## What is ArgoCD?

ArgoCD is a **GitOps continuous delivery tool for Kubernetes**. It automatically syncs your Kubernetes cluster to match the desired state defined in a Git repository — Git becomes the single source of truth for your infrastructure.

---

## The Problem ArgoCD Solves

In a traditional CI/CD pipeline:
```
Code Push → CI builds image → Someone runs kubectl apply → App deployed
```

Problems with this approach:
- Manual `kubectl apply` steps are error-prone
- No single source of truth — cluster state can drift from Git
- Hard to audit who changed what and when
- Rollback means re-running old pipelines
- No visibility into what is actually running vs what should be running

---

## How ArgoCD Fixes This

```
Code Push → CI builds image → Git updated → ArgoCD detects drift → Auto syncs cluster
```

ArgoCD **watches your Git repo** and automatically applies changes to the cluster the moment it detects a difference.

---

## Core Concepts

### 📁 Application
The fundamental ArgoCD unit — it links a **Git repo** to a **Kubernetes cluster + namespace**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app
    targetRevision: HEAD
    path: k8s/overlays/prod          # folder with manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true                    # delete resources removed from Git
      selfHeal: true                 # fix manual changes to cluster
```

### 🔁 Sync
The process of making the cluster match Git. Can be:
- **Manual** — you trigger it
- **Automated** — ArgoCD triggers it on every Git change

### 💚 Sync Status
ArgoCD constantly compares Git vs cluster and reports:

| Status | Meaning |
|---|---|
| `Synced` | Cluster matches Git exactly |
| `OutOfSync` | Cluster differs from Git |
| `Unknown` | Can't determine state |

### ❤️ Health Status
ArgoCD also reports application health:

| Status | Meaning |
|---|---|
| `Healthy` | All resources running fine |
| `Degraded` | Something is broken |
| `Progressing` | Still rolling out |
| `Suspended` | Paused intentionally |

---

## GitOps Flow with ArgoCD

```
┌─────────────┐     push      ┌─────────────┐     watches    ┌─────────────┐
│  Developer  │ ───────────▶  │  Git Repo   │ ◀────────────  │   ArgoCD    │
└─────────────┘               └─────────────┘                └─────────────┘
                                                                     │
                                                                sync │
                                                                     ▼
                                                              ┌─────────────┐
                                                              │ Kubernetes  │
                                                              │  Cluster    │
                                                              └─────────────┘
```

---

## ArgoCD CLI Commands

### Installation & Login
```bash
# Install ArgoCD CLI
brew install argocd                              # macOS
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

# Login to ArgoCD server
argocd login <ARGOCD-SERVER>
argocd login <ARGOCD-SERVER> --insecure         # skip TLS verification

# Get initial admin password
kubectl get secret argocd-initial-admin-secret \
  -n argocd -o jsonpath='{.data.password}' | base64 -d
```

### App Management
```bash
argocd app list                                  # List all applications
argocd app get <app-name>                        # Get app details
argocd app create <app-name>                     # Create an application
argocd app delete <app-name>                     # Delete an application
argocd app sync <app-name>                       # Manually trigger sync
argocd app diff <app-name>                       # Show diff Git vs cluster
argocd app history <app-name>                    # Show sync history
argocd app rollback <app-name> <revision>        # Rollback to a revision
argocd app set <app-name> --sync-policy automated  # Enable auto sync
```

### Cluster & Repo Management
```bash
argocd cluster list                              # List connected clusters
argocd cluster add <context-name>               # Add a cluster
argocd repo list                                 # List connected Git repos
argocd repo add https://github.com/org/repo     # Add a Git repo
argocd repo add <repo> --username <u> --password <p>  # Add private repo
```

### Projects
```bash
argocd proj list                                 # List projects
argocd proj create <project-name>               # Create a project
argocd proj get <project-name>                  # Get project details
argocd proj delete <project-name>               # Delete a project
```

---

## Sync Policies Explained

```yaml
syncPolicy:
  automated:
    prune: true       # Remove k8s resources deleted from Git
    selfHeal: true    # Revert manual kubectl changes automatically
  syncOptions:
    - CreateNamespace=true      # Auto create namespace if missing
    - ApplyOutOfSyncOnly=true   # Only sync changed resources
    - ServerSideApply=true      # Use server-side apply
  retry:
    limit: 5                    # Retry failed syncs 5 times
    backoff:
      duration: 5s
      maxDuration: 3m
```

---

## ArgoCD Supports Multiple Config Formats

| Format | Example |
|---|---|
| Raw Kubernetes YAML | Plain manifests in a folder |
| Helm Charts | `helm install` managed by ArgoCD |
| Kustomize | `kustomization.yaml` overlays |
| Jsonnet | Jsonnet templates |
| Directory | Any folder of YAML files |

---

## ArgoCD vs Traditional CI/CD

| | Jenkins / GitHub Actions | ArgoCD |
|---|---|---|
| **Trigger** | Code push | Git state change |
| **Direction** | Push to cluster | Pull from Git |
| **Source of truth** | Pipeline script | Git repository |
| **Drift detection** | None | Continuous |
| **Rollback** | Re-run old pipeline | `argocd app rollback` |
| **Audit trail** | CI logs | Git history |
| **Visibility** | Build logs | Live UI dashboard |

---

## ArgoCD Architecture

```
┌──────────────────────────────────────────┐
│              ArgoCD Components           │
│                                          │
│  ┌─────────────┐   ┌──────────────────┐  │
│  │  API Server │   │  Repo Server     │  │
│  │  (UI + CLI) │   │  (clones repos)  │  │
│  └─────────────┘   └──────────────────┘  │
│                                          │
│  ┌─────────────────────────────────────┐ │
│  │  Application Controller             │ │
│  │  (watches cluster + syncs state)    │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ┌─────────────┐   ┌──────────────────┐  │
│  │    Redis    │   │    Dex (OIDC)    │  │
│  │   (cache)   │   │  (auth/SSO)      │  │
│  └─────────────┘   └──────────────────┘  │
└──────────────────────────────────────────┘
```

---

## Key Benefits

**🔒 Security** — No CI/CD tool needs direct `kubectl` access to the cluster. ArgoCD runs inside the cluster and pulls changes from Git.

**👁️ Visibility** — Beautiful UI shows every app, its sync status, health, and full resource tree in real time.

**🔁 Drift Detection** — If someone manually runs `kubectl` and changes something, ArgoCD detects the drift and can auto-heal back to Git state.

**📜 Audit Trail** — Every change is a Git commit — you always know who changed what and when, with the ability to revert instantly.

**🚀 Multi-Cluster** — One ArgoCD instance can manage deployments across many Kubernetes clusters simultaneously.

---

## In Short

> ArgoCD turns your Git repository into the control plane for your Kubernetes cluster — any change merged to Git is automatically and safely reflected in your cluster, with full visibility, drift detection, and one-click rollback.
