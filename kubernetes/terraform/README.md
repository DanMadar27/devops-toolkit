# AWS EKS with Tearraform
EKS with Terraform and Helm.

## AWS EKS CLI

Configure kubectl to use EKS credentials:

```bash
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name <your-cluster-name>
```

Then you can check your pods/services etc...:

```bash
kubectl get pods
```