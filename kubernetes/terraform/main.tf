# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # Optional: Allows you to connect to the cluster from your local machine
  endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    spot_nodes = {
      # This is the key to low cost
      capacity_type  = "SPOT"
      instance_types = var.eks_node_instance_types

      min_size     = var.eks_node_min_size
      max_size     = var.eks_node_max_size
      desired_size = var.eks_node_desired_size
    }
  }

  tags = {
    Environment = "test"
    Terraform   = "true"
  }

}

# Wait for EKS control plane to be fully ready
resource "time_sleep" "wait_for_eks" {
  depends_on      = [module.eks]
  create_duration = "60s"
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [time_sleep.wait_for_eks]
}

resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"
  namespace  = "default"

  set = [
    {
      name  = "controller.replicaCount"
      value = "2"
    },
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    }
  ]
}

resource "helm_release" "prometheus" {
  depends_on = [time_sleep.wait_for_eks]

  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "monitoring"
  create_namespace = true

  timeout = 300 # increase from default 300 to 600
  wait    = true

  set = [
    # Keep prometheus internal — no LoadBalancer needed
    { name = "server.service.type", value = "ClusterIP" },
    { name = "server.persistentVolume.enabled", value = "false" }, # no EBS needed (Demo)
    { name = "alertmanager.enabled", value = "false" },            # skip alertmanager
    { name = "prometheus-pushgateway.enabled", value = "false" },  # skip pushgateway
    { name = "server.resources.requests.cpu", value = "100m" },
    { name = "server.resources.requests.memory", value = "256Mi" }
  ]
}
