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

## Observability (Monitoring)

| Tool       | Purpose          | Access        |
|------------|------------------|---------------|
| Prometheus | Metrics collection | Internal only |
| Loki       | Log collection   | Internal only |
| Grafana    | Visualize both   | LoadBalancer  |

### Prometheus

Port-forward and open http://localhost:9090:
```bash
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

Useful pages:
- `localhost:9090` — run PromQL queries
- `localhost:9090/targets` — see all scrape targets and their health

### Loki

Collects logs from all pods via Promtail (runs as a DaemonSet on every node).
Access logs through Grafana Explore tab — no direct UI.

### Grafana

Access via the LoadBalancer URL. Login with credentials set in `terraform.tfvars`.

Import community dashboards from https://grafana.com/grafana/dashboards:
- Node exporter (per node CPU/memory/disk)
- Kubernetes cluster overview
- Loki logs dashboard
````

Fixed a few things along the way — `localhost:9000` → `9090`, and "Locki" → "Loki" (appears twice in your original).