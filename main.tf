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

module "userdata" {
  source  = "ilpozzd/vm-userdata/talos"
  version = "1.0.1"

  count = var.vm_count

  talos_base_configuration = var.talos_base_configuration

  machine_secrets             = var.machine_secrets
  machine_base_configuration  = var.machine_base_configuration
  machine_extra_configuration = var.machine_extra_configuration
  machine_type                = var.create_init_node && var.machine_type == "controlplane" && count.index == 0 ? "init" : var.machine_type
  machine_cert_sans           = length(var.machine_cert_sans) >= count.index + 1 ? var.machine_cert_sans[count.index] : []
  machine_network             = var.machine_network
  machine_network_hostname    = length(var.machine_network_hostnames) >= count.index + 1 ? var.machine_network_hostnames[count.index] : "${local.machine_full_name}-${count.index}"
  machine_network_interfaces  = length(var.machine_network_interfaces) >= count.index + 1 ? var.machine_network_interfaces[count.index] : []

  cluster_secrets                     = var.cluster_secrets
  control_plane_cluster_secrets       = var.control_plane_cluster_secrets
  cluster_name                        = var.cluster_name
  cluster_control_plane               = var.cluster_control_plane
  cluster_discovery                   = var.cluster_discovery
  control_plane_cluster_configuration = var.control_plane_cluster_configuration
  cluster_inline_manifests            = var.machine_type == "controlplane" && count.index == 0 && var.create_init_node ? concat(var.cluster_inline_manifests, [local.vmtoolsd_inline_manifest]) : var.cluster_inline_manifests
  cluster_extra_manifests             = var.machine_type == "controlplane" && count.index == 0 && var.create_init_node ? concat(var.cluster_extra_manifests, [var.vmtoolsd_extra_manifest]) : var.cluster_extra_manifests
  cluster_extra_manifest_headers      = var.cluster_extra_manifest_headers
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
      "talos.config" = module.userdata[count.index].configuration
    }
  }

  lifecycle {
    ignore_changes = [
      disk
    ]
  }
}
