# URL Shortener on k3s (EC2)

A URL shortener with two Python microservices deployed on a self-managed k3s cluster running on AWS EC2.

**Stack:** Terraform · Ansible · k3s · Helm · ArgoCD · Prometheus + Grafana + Loki

## Architecture

```
┌─────────────────────────────────────────────────┐
│  EC2 (t3.medium) — k3s cluster                  │
│                                                 │
│  ┌─────────┐  ┌──────────┐  ┌───────┐          │
│  │ shorten │  │ redirect │  │ redis │          │
│  └─────────┘  └──────────┘  └───────┘          │
│                                                 │
│  ┌───────┐  ┌──────────────────┐  ┌──────────┐ │
│  │ ArgoCD│  │ prometheus-stack │  │   loki   │ │
│  └───────┘  └──────────────────┘  └──────────┘ │
└─────────────────────────────────────────────────┘
```

## Prerequisites

- AWS CLI configured (`aws sts get-caller-identity`)
- Terraform >= 1.6
- Ansible >= 2.14
- Docker
- kubectl

## 1. Provision Infrastructure

```bash
cd terraform/environments/dev
terraform init
terraform apply
```

## 2. Build and Push Images

```bash
ECR_URL=<your-ecr-url>   # e.g. 123456789012.dkr.ecr.eu-central-1.amazonaws.com

aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin $ECR_URL

docker build -t $ECR_URL/url-shortener/shorten:latest services/shorten/
docker push $ECR_URL/url-shortener/shorten:latest

docker build -t $ECR_URL/url-shortener/redirect:latest services/redirect/
docker push $ECR_URL/url-shortener/redirect:latest
```

## 3. Run Ansible

```bash
cd terraform/environments/dev
EC2_IP=$(terraform output -raw ec2_public_ip) # Then edit `ansible/inventory/hosts.yml`
cd ../../../ansible
ansible-playbook -i inventory/hosts.yml site.yml
```

## 4. Update Kubeconfig After EC2 Restart

If the EC2 instance is stopped and restarted (IP changes):

```bash
EC2_IP=$(cd terraform/environments/dev && terraform output -raw ec2_public_ip) # Then edit `ansible/inventory/hosts.yml`
ansible-playbook -i inventory/hosts.yml site.yml --tags kubeconfig
```

## 5. Verify the Cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## 6. Access ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
# user: admin
# password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 7. Access Grafana

```bash
open http://$(cd terraform/environments/dev && terraform output -raw ec2_public_ip):32000
# user: admin / pass: admin
```

## 8. Test the Services

```bash
# Shorten a URL
curl -X POST http://shorten.local/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
# {"short_code": "abc123"}

# Redirect
curl -L http://redirect.local/abc123
```

> Add `shorten.local` and `redirect.local` to `/etc/hosts` pointing at the EC2 public IP.

## 9. Teardown

```bash
cd terraform/environments/dev
terraform destroy
```

## Repository Structure

```
url-shortener/
├── services/
│   ├── shorten/        # POST /shorten FastAPI service
│   └── redirect/       # GET /{code} FastAPI service
├── terraform/
│   ├── modules/
│   │   ├── vpc/        # VPC, subnet, IGW, route table
│   │   ├── ec2/        # EC2 instance, SG, key pair
│   │   └── ecr/        # ECR repositories + lifecycle policies
│   └── environments/
│       └── dev/        # Dev environment wiring + checks + tests
├── ansible/
│   ├── inventory/
│   └── roles/
│       ├── k3s/        # Install and configure k3s
│       ├── kubeconfig/ # Fetch kubeconfig locally
│       └── argocd/     # Install Helm + ArgoCD
├── k8s/
│   ├── apps/
│   │   ├── shorten/    # Helm chart
│   │   ├── redirect/   # Helm chart
│   │   └── redis/      # Bitnami Redis dependency chart
│   ├── monitoring/
│   │   ├── prometheus-stack/
│   │   └── loki-stack/
│   └── argocd/
│       └── app-of-apps.yaml
└── README.md
```
