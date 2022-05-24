locals {
  machine_full_name = "${var.cluster_name}-${var.machine_type}"

  talosconfig = {
    context = "admin@${var.cluster_name}"
    contexts = {
      "admin@${var.cluster_name}" = merge(
        { ca = var.machine_secrets.ca.crt },
        var.talos_admin_pki
      )
    }
  }

  talos_vmtoolsd_secret = {
    apiVersion = "v1"
    kind       = "Secret"
    type       = "Opaque"
    metadata = {
      name      = "talos-vmtoolsd-config"
      namespace = "kube-system"
    }
    stringData = {
      talosconfig = yamlencode(local.talosconfig)
    }
  }

  vmtoolsd_inline_manifest = {
    name     = "vmtoolsd"
    contents = yamlencode(local.talos_vmtoolsd_secret)
  }
}
