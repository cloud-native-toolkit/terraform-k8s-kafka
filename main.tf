provider "helm" {
  version = ">= 1.1.1"

  kubernetes {
    config_path = var.cluster_config_file
  }
}

locals {
  tmp_dir       = "${path.cwd}/.tmp"
  host          = "${var.name}-kafka-bootstrap-${var.app_namespace}.${var.ingress_subdomain}"
  url_endpoint  = "https://${local.host}"
}

resource "null_resource" "kafka-subscription" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-subscription.sh ${var.cluster_type} ${var.app_namespace} ${var.olm_namespace}"

    environment = {
      TMP_DIR    = local.tmp_dir
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "null_resource" "kafka-instance" {
  depends_on = [null_resource.kafka-subscription]

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-instance.sh ${var.cluster_type} ${var.app_namespace} ${var.ingress_subdomain} ${var.name}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "helm_release" "kafka-config" {
  depends_on = [null_resource.kafka-instance]

  name         = "kafka"
  repository   = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  chart        = "tool-config"
  namespace    = var.app_namespace
  force_update = true

  set {
    name  = "url"
    value = local.url_endpoint
  }
}
