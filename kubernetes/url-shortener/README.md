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
- An IAM instance profile named `ReadECR` must exist in your AWS account with ECR read permissions (`AmazonEC2ContainerRegistryReadOnly`). Terraform attaches it to the EC2 instance so k3s can pull images from ECR without static credentials.

## 1. Provision Infrastructure

```bash
cd terraform/environments/dev
terraform init
terraform apply
```

## 2. Build and Push Images

Use explicit version tags instead of `latest` — k8s sets `imagePullPolicy: Always` for `latest` which requires the node to authenticate to ECR on every pod start.

```bash
ECR_URL=<your-ecr-url>   # e.g. 123456789012.dkr.ecr.eu-central-1.amazonaws.com
TAG=v1.0.0

aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin $ECR_URL

docker build -t $ECR_URL/url-shortener/shorten:$TAG services/shorten/
docker push $ECR_URL/url-shortener/shorten:$TAG

docker build -t $ECR_URL/url-shortener/redirect:$TAG services/redirect/
docker push $ECR_URL/url-shortener/redirect:$TAG
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
# password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Set ECR image repository (first time only)

The `image.repository` in `values.yaml` is a placeholder to avoid committing your AWS account ID to a public repo. Override it in ArgoCD UI for each service:

1. Open the `shorten` app → **App Details** → **Edit**
2. Go to the **Parameters** tab → **Add Parameter**
   - Name: `image.repository`
   - Value: `<your-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/url-shortener/shorten`
3. **Save** → **Sync**
4. Repeat for the `redirect` app (change `shorten` → `redirect` in the value)

## 7. Pull Images on the EC2 Node

k3s uses containerd and doesn't automatically inherit AWS credentials for ECR. Pull the images directly on the EC2 node using k3s's built-in `ctr`:

```bash
ECR_URL=<your-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com
TAG=v1.0.0
TOKEN=$(aws ecr get-login-password --region eu-central-1)

sudo k3s ctr images pull --user "AWS:$TOKEN" $ECR_URL/url-shortener/shorten:$TAG
sudo k3s ctr images pull --user "AWS:$TOKEN" $ECR_URL/url-shortener/redirect:$TAG
```

Then in ArgoCD UI, override the following parameters for each app (`shorten` and `redirect`):

| Parameter | Value |
|---|---|
| `image.repository` | `<your-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/url-shortener/shorten` |
| `image.tag` | `v1.0.0` |
| `image.pullPolicy` | `IfNotPresent` |

With `IfNotPresent`, k3s uses the locally pulled image and never needs to contact ECR at runtime.

> Repeat these steps each time you release a new version.

## 8. Access Grafana

```bash
open http://$(cd terraform/environments/dev && terraform output -raw ec2_public_ip):32000
# user: admin / pass: admin
```

## 9. Test the Services

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

## 10. Teardown

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
