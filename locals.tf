locals {
  cluster_etcd_configuration = {
    etcd = merge(
      lookup(var.control_plane_cluster_secrets, "etcd", {}),
      lookup(var.control_plane_cluster_configuration, "etcd", {}),
    )
  }

  control_plane_cluster_secrets       = { for k, v in var.control_plane_cluster_secrets : k => v if k != "etcd" }
  control_plane_cluster_configuration = { for k, v in var.control_plane_cluster_configuration : k => v if k != "etcd" }

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
