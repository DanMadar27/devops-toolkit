# URL Shortener on k3s (EC2) — Implementation Plan

## Project overview

Build a URL shortener with two Python microservices deployed on a self-managed k3s cluster
running on a single AWS EC2 instance. The goal is to practice the full DevOps stack:
Terraform (IaC), Ansible (configuration management), k3s (Kubernetes), Helm, ArgoCD (GitOps),
and Prometheus + Grafana + Loki (observability).

---

## Repository structure

Create the following layout at the root of the repo:

```
url-shortener/
├── services/
│   ├── shorten/
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   └── redirect/
│       ├── main.py
│       ├── requirements.txt
│       └── Dockerfile
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── ec2/
│   │   └── ecr/
│   └── environments/
│       └── dev/
│           ├── main.tf
│           ├── outputs.tf
│           ├── variables.tf
│           ├── checks.tf
│           └── tests/
│               └── dev.tftest.hcl
├── ansible/
│   ├── inventory/
│   │   └── hosts.yml
│   ├── roles/
│   │   ├── k3s/
│   │   ├── kubeconfig/
│   │   └── argocd/
│   └── site.yml
├── k8s/
│   ├── apps/
│   │   ├── shorten/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── deployment.yaml
│   │   │       ├── service.yaml
│   │   │       ├── ingress.yaml
│   │   │       └── hpa.yaml
│   │   ├── redirect/
│   │   │   └── (same structure as shorten)
│   │   └── redis/
│   │       ├── Chart.yaml
│   │       └── values.yaml
│   ├── monitoring/
│   │   ├── prometheus-stack/
│   │   │   └── values.yaml
│   │   └── loki-stack/
│   │       └── values.yaml
│   └── argocd/
│       └── app-of-apps.yaml
└── README.md
```

---

## Step 1 — Python microservices

### Tech stack
- `fastapi`
- `redis`
- `prometheus-fastapi-instrumentator`
- `uvicorn`

### Shorten service (`services/shorten/main.py`)

- `POST /shorten` — accepts `{"url": "https://..."}`, generates a 6-char random alphanumeric
  code, stores `code → url` in Redis with no expiry, returns `{"short_code": "abc123"}`.
- `GET /health` — returns `{"status": "ok"}`.
- `GET /metrics` — Prometheus metrics endpoint (via `prometheus-fastapi-instrumentator`).
- Read Redis connection details from env vars: `REDIS_HOST`, `REDIS_PORT` (default `6379`).

### Redirect service (`services/redirect/main.py`)

- `GET /{code}` — looks up code in Redis. If found, returns HTTP 302 to the original URL.
  If not found, returns HTTP 404 `{"error": "not found"}`.
- `GET /health` — returns `{"status": "ok"}`.
- `GET /metrics` — Prometheus metrics endpoint.
- Same Redis env vars as above.

### Dockerfiles

- Base image: `python:3.12-slim`
- Install deps, copy source, run with `uvicorn main:app --host 0.0.0.0 --port 8000`
- Expose port `8000`

---

## Step 2 — Terraform

### Backend

Configure HCP Terraform (Terraform Cloud) as the backend in `terraform/environments/dev/main.tf`:

```hcl
terraform {
  cloud {
    organization = "your-org-name"
    workspaces {
      name = "url-shortener-dev"
    }
  }
}
```

### Module: `vpc`

Resources:
- `aws_vpc` — CIDR `10.0.0.0/16`
- `aws_subnet` — one public subnet, CIDR `10.0.1.0/24`, `map_public_ip_on_launch = true`
- `aws_internet_gateway`
- `aws_route_table` + `aws_route_table_association`

Outputs: `vpc_id`, `subnet_id`

### Module: `ec2`

Resources:
- `aws_security_group` — allow inbound: SSH (22), HTTP (80), HTTPS (443), k3s API (6443),
  NodePort range (30000–32767). Allow all outbound.
- `aws_key_pair` — accept `public_key` as variable, create key pair in AWS.
- `aws_instance` — AMI: Ubuntu 22.04 (use `data "aws_ami"` to look up latest),
  instance type `t3.medium`, associate with subnet and security group.
  Add `user_data` that sets the hostname only (no k3s install here — Ansible handles that).

Inputs: `vpc_id`, `subnet_id`, `instance_type` (default `t3.medium`), `public_key`
Outputs: `public_ip`, `instance_id`

### Module: `ecr`

Resources:
- `aws_ecr_repository` for `url-shortener/shorten`
- `aws_ecr_repository` for `url-shortener/redirect`
- `aws_ecr_lifecycle_policy` on both — keep last 5 images

Outputs: `shorten_repo_url`, `redirect_repo_url`

### Check blocks (`checks.tf`)

```hcl
check "ec2_running" {
  assert {
    condition     = aws_instance.main.instance_state == "running"
    error_message = "EC2 instance is not in running state"
  }
}
```

### Unit tests (`tests/dev.tftest.hcl`)

Write tests for:
1. VPC CIDR is `10.0.0.0/16`
2. Security group allows port 6443 inbound
3. EC2 instance type is `t3.medium`
4. Both ECR repositories are created

Use `terraform test` syntax (`.tftest.hcl` format with `run` blocks and `assert` blocks).

### `outputs.tf` (dev environment)

Output: `ec2_public_ip` — used by Ansible and the README instructions.

---

## Step 3 — Ansible

### Inventory (`ansible/inventory/hosts.yml`)

```yaml
all:
  hosts:
    k3s_node:
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/your-key.pem
      # ansible_host is passed via CLI: -i "<ip>,"
```

### Role: `k3s`

Tasks in `roles/k3s/tasks/main.yml`:
1. Update apt cache
2. Install curl, git, open-iscsi (k3s dependency)
3. Run k3s install script:
   ```
   curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
   ```
   Note: disable bundled Traefik — we will deploy it ourselves via Helm/ArgoCD for
   version control.
4. Wait until `kubectl get nodes` shows `Ready` (use `wait_for` or `command` with retries)
5. Enable and start `k3s` service

### Role: `kubeconfig`

Tasks in `roles/kubeconfig/tasks/main.yml`:
1. Fetch `/etc/rancher/k3s/k3s.yaml` from the remote host to `~/.kube/config` locally
2. Replace `server: https://127.0.0.1:6443` with `server: https://{{ ansible_host }}:6443`
   using `replace` module
3. Set file permissions to `0600`

### Role: `argocd`

Tasks in `roles/argocd/tasks/main.yml`:
1. Install Helm on the remote host (via apt or official install script)
2. Add ArgoCD Helm repo: `https://argoproj.github.io/argo-helm`
3. Create namespace `argocd`
4. `helm install argocd argo/argo-cd -n argocd --wait`
5. Copy `k8s/argocd/app-of-apps.yaml` to the remote host and `kubectl apply -f` it

### `site.yml`

```yaml
- hosts: all
  become: true
  roles:
    - k3s
- hosts: all
  become: false
  roles:
    - kubeconfig
    - argocd
```

---

## Step 4 — Helm charts

### Shorten + Redirect services

Each chart should contain:

**`templates/deployment.yaml`**
- 2 replicas
- Image from ECR (use `values.yaml` for image repo + tag)
- Env vars: `REDIS_HOST`, `REDIS_PORT` from a ConfigMap
- Liveness probe: `GET /health`
- Readiness probe: `GET /health`
- Resources: requests `cpu: 100m, memory: 128Mi`, limits `cpu: 250m, memory: 256Mi`
- Annotations: `prometheus.io/scrape: "true"`, `prometheus.io/path: "/metrics"`, `prometheus.io/port: "8000"`

**`templates/service.yaml`**
- Type: `ClusterIP`, port 80 → targetPort 8000

**`templates/ingress.yaml`**
- Use standard `networking.k8s.io/v1` Ingress
- Shorten service: `host: shorten.local`, path `/`
- Redirect service: `host: redirect.local`, path `/`

**`templates/hpa.yaml`**
- `minReplicas: 1`, `maxReplicas: 3`
- Scale on CPU at 70% utilization

### Redis chart

Use the official Bitnami Redis chart as a dependency in `k8s/apps/redis/Chart.yaml`:
```yaml
dependencies:
  - name: redis
    version: "19.x.x"
    repository: "https://charts.bitnami.com/bitnami"
```

`values.yaml`: disable persistence (`persistence.enabled: false`), set architecture
to `standalone`, no auth (`auth.enabled: false`) for simplicity.

---

## Step 5 — ArgoCD app-of-apps

### `k8s/argocd/app-of-apps.yaml`

Create one ArgoCD `Application` resource per app (shorten, redirect, redis,
prometheus-stack, loki-stack), plus one parent `Application` that points at the
`k8s/apps/` directory. This is the app-of-apps pattern.

All applications:
- `project: default`
- `source.repoURL`: your GitHub repo URL (make it a variable/comment placeholder)
- `source.targetRevision: HEAD`
- `destination.server: https://kubernetes.default.svc`
- `syncPolicy.automated: {prune: true, selfHeal: true}`

---

## Step 6 — Observability

### Prometheus + Grafana (`k8s/monitoring/prometheus-stack/values.yaml`)

Deploy `kube-prometheus-stack` Helm chart. Key values to set:
- `grafana.enabled: true`
- `grafana.adminPassword: admin` (fine for practice)
- `prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues: false`
  (so it picks up ServiceMonitors from all namespaces)
- `grafana.service.type: NodePort` with `nodePort: 32000` — so you can reach Grafana
  at `http://<ec2-ip>:32000`

### Loki stack (`k8s/monitoring/loki-stack/values.yaml`)

Deploy `loki-stack` Helm chart (includes Loki + Promtail):
- `promtail.enabled: true` — scrapes all pod logs automatically
- `loki.persistence.enabled: false`

In Grafana, add Loki as a data source at `http://loki:3100`.

### Grafana dashboard

Create a ConfigMap in the prometheus-stack values (or as a separate manifest) with a
dashboard JSON that shows:
- HTTP request rate per service (from Prometheus)
- p99 latency per service
- Redis connected clients
- Pod restarts
- A Loki logs panel for each service (filter by pod label)

---

## Step 7 — README

Write a `README.md` with the exact commands to:

1. **Build and push images**
   ```bash
   aws ecr get-login-password | docker login --username AWS --password-stdin <ecr-url>
   docker build -t <ecr-url>/url-shortener/shorten:latest services/shorten/
   docker push <ecr-url>/url-shortener/shorten:latest
   # same for redirect
   ```

2. **Provision infrastructure**
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform apply
   ```

3. **Run Ansible**
   ```bash
   EC2_IP=$(terraform output -raw ec2_public_ip)
   cd ../../../ansible
   ansible-playbook -i "${EC2_IP}," site.yml
   ```

4. **Update kubeconfig after EC2 restart** (IP changed)
   ```bash
   EC2_IP=$(cd terraform/environments/dev && terraform output -raw ec2_public_ip)
   ansible-playbook -i "${EC2_IP}," site.yml --tags kubeconfig
   ```

5. **Verify the cluster**
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

6. **Access Grafana**
   ```bash
   open http://$(cd terraform/environments/dev && terraform output -raw ec2_public_ip):32000
   # user: admin / pass: admin
   ```

7. **Teardown**
   ```bash
   cd terraform/environments/dev
   terraform destroy
   ```

---

## Implementation notes for Claude Code

- Do not generate any AWS account IDs, real IP addresses, or real credentials anywhere.
  Use placeholder values like `<your-aws-account-id>`, `<your-ecr-url>`, `<your-github-repo>`.
- All Terraform variables that differ per environment should be in `variables.tf` with
  sensible defaults. Do not hardcode region — default to `eu-central-1` but make it a variable.
- The Ansible roles should be idempotent — running the playbook twice should not fail or
  cause side effects.
- Tag all AWS resources with `Project = "url-shortener"` and `Environment = "dev"`.
- Use `.gitignore` to exclude: `.terraform/`, `*.tfstate`, `*.tfstate.backup`,
  `ansible/inventory/ec2_ip.txt`, `**/__pycache__/`, `.env`.
- Each service directory should include a `.env.example` file with the required env vars.
