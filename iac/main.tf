provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace_v1" "monitor_team" {
  metadata {
    annotations = {
      name = "terraform-managed"
    }

    labels = {
      tools = "monitoring"
    }

    name = var.team-monitor-ns
  }
}

resource "kubernetes_namespace_v1" "apps_team" {
  metadata {
    annotations = {
      name = "terraform-managed"
    }

    labels = {
      app = "autoscaled-apps"
    }

    name = var.team-apps-ns
  }
}

resource "kubernetes_namespace_v1" "mgmt_team" {
  metadata {
    annotations = {
      name = "terraform-managed"
    }

    labels = {
      app = "mgmt"
    }

    name = var.team-mgmt-ns
  }
}

resource "kubernetes_namespace_v1" "istio" {
  metadata {
    annotations = {
      name = "terraform-managed"
    }

    labels = {
      app = "istio"
    }

    name = "istio-system"
  }
}


resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "49.2.0"
  create_namespace = true
  namespace        = var.team-monitor-ns
  values = [
    file("../helm/kube-prometheus-stack/Values.yaml")
  ]

  timeout = 180
  depends_on = [
    kubernetes_namespace_v1.monitor_team
  ]
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.12.1"
  create_namespace = true
  namespace        = var.team-monitor-ns
  values = [
    file("../helm/metrics-server/Values.yaml")
  ]

  timeout = 180
}

resource "helm_release" "prometheus_adapter" {
  name             = "prometheus-adapter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-adapter"
  version          = "4.10.0"
  create_namespace = true
  namespace        = var.team-monitor-ns
  values = [
    file("../helm/prometheus-adapter/Values.yaml")
  ]

  timeout = 180
  depends_on = [
    kubernetes_namespace_v1.monitor_team,
    helm_release.kube_prometheus_stack
  ]
}

resource "helm_release" "vertical_pod_autoscaler" {
  name             = "vertical-pod-autoscaler"
  repository       = "https://cowboysysop.github.io/charts/"
  chart            = "vertical-pod-autoscaler"
  version          = "9.8.2"
  create_namespace = true
  namespace        = var.team-monitor-ns
  values = [
    file("../helm/vertical-pod-autoscaler/Values.yaml")
  ]

  timeout = 300
  depends_on = [
    kubernetes_namespace_v1.monitor_team,
    helm_release.kube_prometheus_stack
  ]
}

resource "helm_release" "kubeshark" {
  name             = "kubeshart"
  repository       = "https://helm.kubeshark.co"
  chart            = "kubeshark"
  version          = "52.3.69"
  create_namespace = true
  namespace        = var.team-monitor-ns
  values = [
    file("../helm/kubeshark/Values.yaml")
  ]

  timeout = 300
  depends_on = [
    kubernetes_namespace_v1.monitor_team,
    helm_release.kube_prometheus_stack
  ]
}

resource "helm_release" "istio" {
  name             = "istio"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istio"
  version          = "52.3.69"
  create_namespace = true
  namespace        = var.team-monitor-ns
  values = [
    file("../helm/kubeshark/Values.yaml")
  ]

  timeout = 300
  depends_on = [
    kubernetes_namespace_v1.monitor_team,
    helm_release.kube_prometheus_stack
  ]
}
/* 
resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.3.6"
  create_namespace = true
  namespace        = var.team-mgmt-ns
  values = [
    file("../helm/argo-cd/Values.yaml")
  ]

  timeout = 300
  depends_on = [
    kubernetes_namespace_v1.mgmt_team,
    helm_release.kube_prometheus_stack
  ]
} */


/* resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = var.team-monitor-ns # Ensure Prometheus is deployed in this namespace
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      port        = 9090
      target_port = 9090
    }

    type = "LoadBalancer"
  }
  depends_on = [helm_release.kube_prometheus_stack]
}

resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.team-monitor-ns # Ensure Grafana is deployed in this namespace
  }

  spec {
    selector = {
      app = "grafana"
    }

    port {
      port        = 3000
      target_port = 3000
    }

    type = "LoadBalancer"
  }
  depends_on = [helm_release.kube_prometheus_stack]
}

resource "kubernetes_service" "argocd-server" {
  metadata {
    name      = "argocd-server"
    namespace = var.team-mgmt-ns # Ensure ArgoCD is deployed in this namespace
  }

  spec {
    selector = {
      app = "argocd-server"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
  depends_on = [helm_release.argocd]
}
 */
resource "kubernetes_deployment" "example-app" {
  metadata {
    name      = "hpa-vpa-sample-app"
    namespace = var.team-apps-ns
    labels = {
      test = "hpa-vpa-sample-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "hpa-vpa-sample-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "hpa-vpa-sample-app"
        }
      }

      spec {
        container {
          image = "luxas/autoscale-demo:v0.1.2"
          name  = "metrics-provider"
          port {
            name           = "http"
            container_port = 8888
          }
          /*           resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          } */
        }
      }
    }
  }
  depends_on = [kubernetes_namespace_v1.apps_team]
}

resource "kubernetes_service" "example-app-svc" {
  metadata {
    name      = "hpa-vpa-sample-app"
    namespace = var.team-apps-ns # Ensure ArgoCD is deployed in this namespace
    labels = {
      app = "hpa-vpa-sample-app"
    }
  }

  spec {
    selector = {
      app = "hpa-vpa-sample-app"
    }

    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = 8081
    }

    type = "ClusterIP"
  }
  depends_on = [kubernetes_deployment.example-app]
}


/*
data "kubernetes_service" "grafana" {
  depends_on = [ helm_release.kube_prometheus_stack ]
  metadata {
    name = "kube-prometheus-stack-grafana"
    namespace = "monitoring"
  }
}

resource "null_resource" "kubectl_port_forward" {
  count = 1
  depends_on = [ 
    helm_release.kube_prometheus_stack, 
    data.kubernetes_service.grafana
  ]
  triggers = {
    service_status = data.kubernetes_service.grafana.spec[0].cluster_ip
  }

  provisioner "local-exec" {
    #command = "kubectl get svc -n monitoring"
    #command = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
    command = "kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 &> /dev/null &"
  }
} */