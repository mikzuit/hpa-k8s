provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "51.1.0"
  create_namespace = true
  namespace        = "tools-limited-namespace"
  values = [
    file("../helm/kube-prometheus-stack/Values.yaml")
  ]

  timeout = 180
  depends_on = [ helm_release.vertical_pod_autoscaler ]
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.12.1"
  create_namespace = true
  namespace = "kube-system"
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
  namespace = "tools-limited-namespace"
  values = [
    file("../helm/prometheus-adapter/Values.yaml")
  ]

  timeout = 180
  depends_on = [ helm_release.kube_prometheus_stack ]
}

resource "helm_release" "vertical_pod_autoscaler" {
  name             = "vertical-pod-autoscaler"
  repository       = "https://cowboysysop.github.io/charts/"
  chart            = "vertical-pod-autoscaler"
  version          = "9.8.2"
  create_namespace = true
  namespace = "tools-limited-namespace"
  values = [
    file("../helm/vertical-pod-autoscaler/Values.yaml")
  ]

  timeout = 300
  depends_on = [ helm_release.metrics_server ]
}

# resource "helm_release" "nginx" {
#   name             = "bitnami-nginx"
#   repository       = "https://charts.bitnami.com/bitnami"
#   chart            = "nginx"
#   version          = "13.2.29"
#   create_namespace = true
#   namespace = "tools-limited-namespace"
#   values = [
#     file("../helm/nginx/Values.yaml")
#   ]

#   timeout = 300
#   depends_on = [ helm_release.metrics_server ]
# }

/* resource "helm_release" "microservice" {
  name             = "my-hello-springboot-microservice"
  repository       = "https://siakhooi.github.io/helm-charts"
  chart            = "hello-springboot-microservice"
  version          = "0.21.0"
  namespace = "tools-limited-namespace"
  values = [
    file("../helm/microservice/Values.yaml")
  ]

  timeout = 300
  depends_on = [ helm_release.metrics_server ]
} */
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