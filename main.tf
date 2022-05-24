terraform {
  experiments = [
    module_variable_optional_attrs
  ]

  required_version = ">= 1.1.9, < 2.0.0"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.1.1"
    }
  }
}

resource "vsphere_virtual_machine" "this" {
  count = var.vm_count

  datacenter_id    = data.vsphere_datacenter.this.id
  datastore_id     = data.vsphere_ovf_vm_template.this[count.index].datastore_id
  host_system_id   = data.vsphere_ovf_vm_template.this[count.index].host_system_id
  resource_pool_id = data.vsphere_ovf_vm_template.this[count.index].resource_pool_id
  folder           = var.folder

  name = length(var.machine_network_hostnames) >= count.index + 1 ? var.machine_network_hostnames[count.index] : "${local.machine_full_name}-${count.index}"

  num_cpus = var.num_cpus
  memory   = var.memory

  dynamic "network_interface" {
    for_each = data.vsphere_ovf_vm_template.this[count.index].ovf_network_map
    content {
      network_id = network_interface.value
    }
  }

  dynamic "disk" {
    for_each = var.disks
    content {
      label            = disk.value["label"]
      size             = disk.value["size"]
      eagerly_scrub    = lookup(disk.value, "eagerly_scrub", false)
      thin_provisioned = index(var.disks, disk.value) == 0 ? false : lookup(disk.value, "thin_provisioned", false)
      io_share_count   = index(var.disks, disk.value) == 0 ? 1000 : 0
      unit_number      = index(var.disks, disk.value)
    }
  }

  guest_id = data.vsphere_ovf_vm_template.this[count.index].guest_id

  ovf_deploy {
    remote_ovf_url  = data.vsphere_ovf_vm_template.this[count.index].remote_ovf_url
    ovf_network_map = data.vsphere_ovf_vm_template.this[count.index].ovf_network_map
  }

  enable_disk_uuid = true

  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 10

  vapp {
    properties = {
      "talos.config" = base64encode(
        replace(
          yamlencode(
            merge(
              var.talos_base_configuration,
              {
                machine = merge(
                  var.machine_secrets,
                  var.machine_base_configuration,
                  var.machine_extra_configuration,
                  { type = var.create_init_node && var.machine_type == "controlplane" && count.index == 0 ? "init" : var.machine_type },
                  { certSANs = length(var.machine_cert_sans) >= count.index + 1 ? var.machine_cert_sans[count.index] : [] },
                  {
                    network = merge(
                      var.machine_network,
                      { hostname = length(var.machine_network_hostnames) >= count.index + 1 ? var.machine_network_hostnames[count.index] : "${local.machine_full_name}-${count.index}" },
                      { interfaces = length(var.machine_network_interfaces) >= count.index + 1 ? var.machine_network_interfaces[count.index] : [] }
                    )
                  }
                )
              },
              {
                cluster = merge(
                  var.cluster_secrets,
                  local.control_plane_cluster_secrets,
                  local.cluster_etcd_configuration,
                  { clusterName = var.cluster_name },
                  { controlPlane = var.cluster_control_plane },
                  { discovery = var.cluster_discovery },
                  local.control_plane_cluster_configuration,
                  { inlineManifests = var.machine_type == "controlplane" && count.index == 0 && var.create_init_node ? concat(var.cluster_inline_manifests, [local.vmtoolsd_inline_manifest]) : var.cluster_inline_manifests },
                  { extraManifests = var.machine_type == "controlplane" && count.index == 0 && var.create_init_node ? concat(var.cluster_extra_manifests, [var.vmtoolsd_extra_manifest]) : var.cluster_extra_manifests },
                  { extraManifestHeaders = var.cluster_extra_manifest_headers }
                )
              }
            )
          ),
        "/.*: null\n/", "")
      )
    }
  }
}
