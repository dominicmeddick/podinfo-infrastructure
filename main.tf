resource "kind_cluster" "default" {
  provider = kind
  name     = "test-cluster"
}

resource "helm_release" "podinfo" {
  chart     = "../podinfo/charts/podinfo"
  name      = "podinfo"
  namespace = kubernetes_namespace_v1.podinfo.metadata[0].name

  set = [
    {
      name  = "resources.limits.cpu"
      value = "100m"
    },
    {
      name  = "resources.limits.memory"
      value = "128Mi"
    }
  ]

  depends_on = [kubernetes_namespace_v1.podinfo]
}

resource "kubernetes_namespace_v1" "podinfo" {
  metadata {
    name = "podinfo"
  }
}

resource "kubernetes_resource_quota_v1" "podinfo" {
  metadata {
    name      = "podinfo-quota"
    namespace = kubernetes_namespace_v1.podinfo.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "1"
      "requests.memory" = "1Gi"
      "limits.cpu"      = "2"
      "limits.memory"   = "2Gi"
      "pods"            = "10"
    }
  }
}

resource "kubernetes_network_policy_v1" "podinfo" {
  metadata {
    name      = "podinfo-network-policy"
    namespace = kubernetes_namespace_v1.podinfo.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "podinfo"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "podinfo"
          }
        }
      }
    }
    policy_types = ["Ingress"]
  }
}

## ---------------- ##
   ## ArgoCD ##
## ---------------- ##

resource "kubernetes_namespace_v1" "argocd" {
    metadata {
      name = "argocd"
    }
}

resource "helm_release" "argocd" {
    name = "argocd"
    repository = "https://argoproj.github.io/argo-helm"
    chart = "argo-cd"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    
    depends_on = [kubernetes_namespace_v1.argocd]
}
