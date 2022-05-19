data "vsphere_datacenter" "this" {
  name = var.datacenter
}

data "vsphere_datastore" "this" {
  count         = var.vm_count
  name          = var.datastores[count.index % length(var.datastores)]
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_host" "this" {
  count         = var.vm_count
  name          = var.hosts[count.index % length(var.hosts)]
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_resource_pool" "this" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_network" "this" {
  count         = length(var.network_interfaces)
  name          = var.network_interfaces[count.index].name
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_ovf_vm_template" "this" {
  count            = var.vm_count
  name             = "${local.machine_full_name}-${count.index}"
  resource_pool_id = data.vsphere_resource_pool.this.id
  datastore_id     = data.vsphere_datastore.this[count.index].id
  host_system_id   = data.vsphere_host.this[count.index].id
  remote_ovf_url   = var.remote_ovf_url

  ovf_network_map = {
    for network in data.vsphere_network.this : "VM Network" => network.id
  }
}
