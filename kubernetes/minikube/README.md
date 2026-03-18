# Minikube

Minikube is a tool that lets you run Kubernetes locally. minikube runs an all-in-one or a multi-node local Kubernetes cluster on your personal computer (including Windows, macOS and Linux PCs) so that you can try out Kubernetes, or for daily development work. Then you can use `kubectl` to interact with the control plane API.

Links:

- [Minikube Basic Tutorial](https://kubernetes.io/docs/tutorials/hello-minikube/)

## Minikube CLI

Create a minikube cluster (If not exist):

```bash
minikube start
```

Check status of minikube cluster:

```bash
minikube status
```

Stop minikube cluster:

```bash
minikube stop
```

Delete minikube cluster:

```bash
minikube delete
```

Open dashboard:

```bash
minikube dashboard
```

Expose service:

```bash
minikube service <my-service>

# Or with port-forwarding:
kubectl port-forward svc/<my-service> <host-port>:<container-port>
```