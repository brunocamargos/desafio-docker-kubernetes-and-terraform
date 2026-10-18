resource "kind_cluster" "this" {
  name            = var.cluster_name
  kubeconfig_path = pathexpand("~/.kube/config")

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
    }
  }
}

resource "terraform_data" "images" {
  triggers_replace = [kind_cluster.this.id]

  provisioner "local-exec" {
    working_dir = "${path.module}/../../app"
    command     = <<-EOT
      docker build -t mural-api:local -f docker/api.Dockerfile .
      docker build -t mural-web:local -f docker/web.Dockerfile .
      kind load docker-image mural-api:local mural-web:local --name ${var.cluster_name}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "docker rmi -f mural-api:local mural-web:local"
  }
}

resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = "42.0.0"
  namespace        = "traefik"
  create_namespace = true

  set = [
    { name = "ports.web.hostPort", value = "80" },
    { name = "service.spec.type", value = "ClusterIP" },
  ]
}

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "kubernetes_namespace_v1" "mural" {
  metadata {
    name = "mural"
  }
}

resource "helm_release" "mural" {
  name      = "mural"
  chart     = "${path.module}/../helm/mural"
  namespace = kubernetes_namespace_v1.mural.metadata[0].name

  set = [{ name = "ingress.host", value = var.host }]

  set_sensitive = [{ name = "postgres.password", value = random_password.db.result }]

  depends_on = [terraform_data.images, helm_release.traefik]
}
