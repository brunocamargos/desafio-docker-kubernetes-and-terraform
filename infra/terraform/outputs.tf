output "url" {
  value = "http://${var.host}"
}

output "kubectl_context" {
  value = "kind-${var.cluster_name}"
}
