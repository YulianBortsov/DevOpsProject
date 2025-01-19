module "loki_stack" {
  source = "terraform-iaac/loki-stack/kubernetes"

  namespace        = "monitoring"
  create_namespace = false

  provider_type          = "local"
  pvc_storage_class_name = "gp2"
  pvc_access_modes       = ["ReadWriteOnce"]
  persistent_volume_size = "10Gi"

  loki_resources = {
    request_cpu    = "100m"
    request_memory = "256Mi"
  }

  promtail_resources = {
    request_cpu    = "50m"
    request_memory = "128Mi"
  }
  depends_on = [
    helm_release.karpenter,
    module.karpenter,
    kubectl_manifest.karpenter_node_class,
    kubectl_manifest.karpenter_node_pool
  ]
                  
}