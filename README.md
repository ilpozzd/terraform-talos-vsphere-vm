# Talos OS vSphere Virtual Machine Terraform Module

This module allows you to deploy a Talos OS-based vSphere virtual machine with a custom configuration. It is a child module of [ilpozzd/terraform-talos-vsphere-cluster](https://github.com/ilpozzd/terraform-talos-vsphere-cluster).
The configuration of the virtual machine fully corresponds to the configuration of [Talos OS v1.0.x](https://www.talos.dev/v1.0/).

## Usage

It is strongly not recommended to use this module separately, since creating groups of virtual machines does not make a full cycle of Terraform automation (you cannot continue working with the created cluster using Terraform). To create a cluster, use [ilpozzd/terraform-talos-vsphere-cluster](https://github.com/ilpozzd/terraform-talos-vsphere-cluster). This module is useful in some cases when using Terragrunt. See [examples](#examples).

## Examples

* [Terragrunt Example](https://github.com/ilpozzd/talos-vsphere-cluster-terragrunt-example)

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.1.9 |
| [hashicorp/vsphere](https://registry.terraform.io/providers/hashicorp/vspherehttps://registry.terraform.io/providers/hashicorp/vsphere) | >= 2.1.1 |

**vSphere Version** >= `6.7u3`

### Required `Terraform Role` permissions in **vSphere**

Datastore:
* Allocate space
* Browse datastore
* Low level file operations
* Remove file
* Update virtual machine files
* Update virtual machine metadata

Folder:
* Create folder
* Delete folder
* Move folder
* Rename folder

Network:
* Assign network

Resource:
* Assign virtual machine to resource pool
* Migrate powered off virtual machine
* Migrate powered on virtual machine

Profile-driven storage:
* Profile-driven storage view

vApp:
* Import
* View OVF environment
* vApp application configuration
* vApp instance configuration
* vApp managedBy configuration
* vApp resource configuration

Virtual machine:
* Change Configuration
* Edit Inventory
* Guest Operations
* Interaction
* Provisioning

### Required objects to apply `roles`

* vCenter -> `Terraform Role` -> This Object
* Datacenter -> `Read-only Role` -> This object
* Datastore Cluster -> `Terraform Role` -> This object and it`s children
* Hosts Cluster -> `Read-only Role` -> This object
* Hosts -> `Terraform Role` -> This Object
* DPG -> `Terraform Role` -> This object
* Folder -> `Terraform Role` -> This object and it`s children
* Resource pool -> `Terraform Role` -> This object and it`s children

## Providers

| Name | Version |
|---|---|
| [hashicorp/vsphere](https://registry.terraform.io/providers/hashicorp/vspherehttps://registry.terraform.io/providers/hashicorp/vsphere) | >= 2.1.1 |

## Modules

No modules.

## Resources

| Name | Type |
|---|---|
| [vsphere_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| datacenter | VMware datacenter name. | `string` | `-` | Yes |
| datastores | VMWare datastore(s) where all virtual machine`s data will be placed in. | `list(string)` | `-` | Yes |
| hosts | ESXi host(s) where target virtual machine will be created. | `list(string)` | `-` | Yes |
| resource_pool | VMWare resource pool where target virtual machine will be created. | `string` | `-` | Yes |
| folder | Folder to create the virtual machine in. | `string` | `-` | Yes |
| remote_ovf_url | URL to the remote Talos OS ovf/ova file. | `string` | `-` | Yes |
| <a name="vm-count-cell"></a> vm_count | Number of virtual machines. | `number` | `1` | No |
| num_cpus | The total number of virtual processor cores to assign to this virtual machine. | `number` | `2` | No |
| memory | The size of the virtual machine`s RAM, in Mb. | `number` | `2048` | No |
| disks | A specification list for a virtual disk devices on this virtual machine. | [`list`](#disks-input) | `-` | Yes |
| network_interfaces | A specification list for a virtual NIC on this virtual machine. | [`list`](#network-interfaces-input) | `-` | Yes |
| <a name="create-init-node-cell"></a> create_init_node | Whether to create an initialization node. If `true`, the `first` virtual machine will be the initialization node. | `bool` | `false` | Yes |
| talos_base_configuration | Talos high-level configuration. | [`object`](#talos-base-configuration-input) | [`object`](#talos-base-configuration-input) | No |
| machine_secrets | Secret data used to create Talos stack. | [`object`](#machine-secrets-input) | `-` | Yes |
| talos_admin_pki | Base64 encoded certificate (signed by [machine_secrets.ca.crt](#machine-secrets-input) and key (in ED25519) to provide access to virtual machine trought `talosctl`. | [`object`](#talos-admin-pki-input) | `{}` | [Yes](#talos-admin-pki-input) |
| machine_base_configuration | Machine configuration used in all nodes. | [`object`](#machine-base-configuration-input) | `-` | Yes |
| machine_extra_configuration | Optional machine extra configuration. | [`object`](#machine-extra-configuration-input) | `{}` | No |
| <a name="machine-type-cell"></a> machine_type | Machine's role in the Kubernetes cluster (`controlplane` or `worker`). | `string` | `-` | Yes |
| machine_cert_sans | A list of certSANs for [vm_count](#vm-count-cell) virtual machines (optional). | `list(list(string))` | `[]` | No |
| machine_network | Network configuration used in all nodes. | [`object`](#machine-network-input) | `{}` | No |
| <a name="machine-network-hostnames-cell"></a> machine_network_hostnames | A list of hostnames for [vm_count](#vm-count-cell) virtual machines (if not set will be generated automaticly). | `list(string)` | `[]` | No |
| <a name="machine-network-interfaces-cell"></a> machine_network_interfaces | A list of network interfaces for [vm_count](#vm-count-cell) virtual machines (if not set DHCP will be used). If [machine_type](#machine-type-cell) = `controlplane` and [create_init_node](#create-init-node-cell) = `true`, not less than one element with one static IP address required. | [`list`](#machine-network-interfaces-input) | `[]` | No |
| cluster_secrets | Secret data used in all Kubernetes nodes. | [`object`](#cluster-secrets-input) | `-` | Yes |
| control_plane_cluster_secrets | Secret data used in Kubernetes control plane nodes. | [`object`](#control-plane-cluster-secrets-input) | `{}` | [Yes](#control-plane-cluster-secrets-input) |
| cluster_name | The name of the cluster. | `string` | `-` | Yes |
| cluster_control_plane | Provides control plane specific configuration options. | [`object`](#cluster-control-plane-input) | `-` | [No](#cluster-control-plane-input) |
| cluster_discovery | Configures cluster member discovery. | [`object`](#cluster-discovery-input) | [`object`](#cluster-discovery-input) | No |
| control_plane_cluster_configuration | Cluster configuration used in Kubernetes control plane nodes. | [`object`](#control-plane-cluster-configuration-input) | `{}` | No |
| cluster_inline_manifests | A list of inline Kubernetes manifests. | [`list`](#cluster-inline-manifests-input) | `[]` | No |
| cluster_extra_manifests | A list of urls that point to additional manifests. These will get automatically deployed as part of the bootstrap. | `list(string)` | `[]` | No |
| cluster_extra_manifest_headers | A map of key value pairs that will be added while fetching the extraManifests. | `map(string)` | `{}` | No |
| vmtoolsd_extra_manifest | A link to talos-vmtoolsd Kubernetes manifest. | `string` | [`Link`](https://raw.githubusercontent.com/mologie/talos-vmtoolsd/release-0.3/deploy/0.3.yaml) | No |

### Disks Input

```hcl
list(object({
  label = string
  size  = number
}))
```
* label - Any name for disk (label for Terraform)
* size - Capacity in **Gb**

### Network Interfaces Input

```hcl
list(object({
  name = string
}))
```
* name - Distributed Port Group (DPG) name

### Talos Base Configuration Input

```hcl
object({
  version = string
  persist = bool
})
```

Default:

```hcl
{
  version = "v1alpha1"
  persist = false
}
```

See [Config](https://www.talos.dev/v1.0/reference/configuration/#config) section in Talos Configuration Reference for detail description.

### Machine Secrets Input

```hcl
object({
  token = string
  ca = object({
    crt = string
    key = string
  })
})
```

See [MachineConfig](https://www.talos.dev/v1.0/reference/configuration/#machineconfig) section in Talos Configuration Reference for detail description.

### Talos Admin PKI Input

```hcl
object({
  crt = optional(string)
  key = optional(string)
})
```
* crt - Base64 encoded certificate in PEM format
* key - Base64 encoded key in PEM format
  
Required if [machine_type](#machine-type-cell) = `controlplane` and [create_init_node](#create-init-node-cell) = `true`

### Machine Base Configuration 

```hcl
object({
  install = object({
    disk            = string
    extraKernelArgs = optional(list(string))
    image           = string
    bootloader      = bool
    wipe            = bool
    diskSelector = optional(object({
      size    = string
      model   = string
      busPath = string
    }))
    extensions = optional(list(string))
  })
  kubelet = optional(object({
    image      = string
    extraArgs  = optional(map(string))
    clusterDNS = optional(list(string))
    extraMounts = optional(list(object({
      destination = string
      type        = string
      source      = string
      options     = list(string)
    })))
    extraConfig = optional(map(string))
    nodeIP = optional(object({
      validSubnets = list(string)
    }))
  }))
  time = optional(object({
    disabled    = optional(bool)
    servers     = optional(list(string))
    bootTimeout = optional(string)
  }))
  features = optional(object({
    rbac = optional(bool)
  }))
})
```

See [MachineConfig](https://www.talos.dev/v1.0/reference/configuration/#machineconfig) section in Talos Configuration Reference for detail description.

### Machine Extra Configuration Input

```hcl
object({
  controlPlane = optional(object({
    controllerManager = object({
      disabled = bool
    })
    scheduler = object({
      disabled = bool
    })
  }))
  pods = optional(list(map(any)))
  disks = optional(list(object({
    device = string
    partitions = list(object({
      mountpoint = string
      size       = string
    }))
  })))
  files = optional(list(object({
    content     = string
    permissions = string
    path        = string
    op          = string
  })))
  env = optional(object({
    GRPC_GO_LOG_VERBOSITY_LEVEL = optional(string)
    GRPC_GO_LOG_SEVERITY_LEVEL  = optional(string)
    http_proxy                  = optional(string)
    https_proxy                 = optional(string)
    no_proxy                    = optional(bool)
  }))
  sysctl = optional(map(string))
  sysfs  = optional(map(string))
  registries = optional(object({
    mirrors = optional(map(object({
      endpoints = list(string)
    })))
    config = optional(map(object({
      tls = object({
        insecureSkipVerify = bool
        clientIdentity = optional(object({
          crt = string
          key = string
        }))
        ca = optional(string)
      })
      auth = optional(object({
        username      = optional(string)
        password      = optional(string)
        auth          = optional(string)
        identityToken = optional(string)
      }))
    })))
  }))
  systemDiskEncryption = optional(map(object({
    provider = string
    keys = optional(list(object({
      static = optional(object({
        passphrase = string
      }))
      nodeID = optional(map(string))
      slot   = optional(number)
    })))
    cipher    = optional(string)
    keySize   = optional(number)
    blockSize = optional(number)
    options   = optional(list(string))
  })))
  udev = optional(object({
    rules = list(string)
  }))
  logging = optional(object({
    destinations = list(object({
      endpoint = string
      format   = string
    }))
  }))
  kernel = optional(object({
    modules = list(object({
      name = string
    }))
  }))
})
```

See [MachineConfig](https://www.talos.dev/v1.0/reference/configuration/#machineconfig) section in Talos Configuration Reference for detail description.

### Machine Network Input

```hcl
object({
  nameservers = optional(list(string))
  extraHostEntries = optional(list(object({
    ip      = string
    aliases = list(string)
  })))
  kubespan = optional(object({
    enabled = bool
  }))
})
```
See [NetworkConfig](https://www.talos.dev/v1.0/reference/configuration/#networkconfig) section in Talos Configuration Reference for detail description. 

[hostname](#machine-network-hostnames-cell) and [interfaces](#machine-network-interfaces-cell) parameters are described in separate inputs.

### Machine Network Interfaces Input

```hcl
list(list(object({
  interface = string
  addresses = optional(list(string))
  routes = optional(list(object({
    network = string
    gateway = optional(string)
    source  = optional(string)
    metric  = optional(number)
  })))
  vlans = optional(list(object({
    addresses = list(string)
    routes = optional(list(object({
      network = string
      gateway = optional(string)
      source  = optional(string)
      metric  = optional(number)
    })))
    dhcp   = optional(bool)
    vlanId = number
    mtu    = number
    vip = optional(object({
      ip = string
      equinixMetal = optional(object({
        apiToken = string
      }))
      hcloud = optional(object({
        apiToken = string
      }))
    }))
  })))
  mtu = optional(number)
  bond = optional(object({
    interfaces = list(string)
    mode       = string
    lacpRate   = string
  }))
  dhcp   = optional(bool)
  ignore = optional(bool)
  dummy  = optional(bool)
  dhcpOptions = optional(object({
    routeMetric = number
    ipv4        = optional(bool)
    ipv6        = optional(bool)
  }))
  wireguard = optional(object({
    privateKey   = string
    listenPort   = number
    firewallMark = number
    peers = list(object({
      publicKey                   = string
      endpoint                    = string
      persistentKeepaliveInterval = optional(string)
      allowedIPs                  = list(string)
    }))
  }))
  vip = optional(object({
    ip = string
    equinixMetal = optional(object({
      apiToken = string
    }))
    hcloud = optional(object({
      apiToken = string
    }))
  }))
})))
```

See [Device](https://www.talos.dev/v1.0/reference/configuration/#device) section in Talos Configuration Reference for detail description. 

### Cluster Secrets Input

```hcl
object({
  id     = string
  secret = string
  token  = string
  ca = object({
    crt = string
    key = string
  })
})
```
See [ClusterConfig](https://www.talos.dev/v1.0/reference/configuration/#clusterconfig) section in Talos Configuration Reference for detail description. 

### Control Plane Cluster Secrets Input

```hcl
object({
  aescbcEncryptionSecret = optional(string)
  aggregatorCA = optional(object({
    crt = optional(string)
    key = optional(string)
  }))
  serviceAccount = optional(object({
    key = optional(string)
  }))
  etcd = optional(object({
    ca = object({
      crt = optional(string)
      key = optional(string)
    })
  }))
})
```

See [ClusterConfig](https://www.talos.dev/v1.0/reference/configuration/#clusterconfig) section in Talos Configuration Reference for detail description.

Required if [machine_type](#machine-type-cell) = `controlplane`.

### Cluster Control Plane Input

```hcl
object({
  endpoint           = optional(string)
  localAPIServerPort = optional(number)
})
```

See [ControlPlaneConfig](https://www.talos.dev/v1.0/reference/configuration/#controlplaneconfig) section in Talos Configuration Reference for detail description. 

Required if ([create_init_node](#create-init-node-cell) = `false` or ([create_init_node](#create-init-node-cell) = `true` and [vm_count](#vm-count-cell) > `1`)).

### Cluster Discovery Input

```hcl
object({
  enabled = bool
  registries = optional(object({
    kubernetes = optional(object({
      disabled = bool
    }))
    service = optional(object({
      disabled = bool
      endpoint = string
    }))
  }))
})
```

Default:

```hcl
{
  enabled = true
}
```

See [ClusterDiscoveryConfig](https://www.talos.dev/v1.0/reference/configuration/#clusterdiscoveryconfig) section in Talos Configuration Reference for detail description.

### Control Plane Cluster Configuration Input

```hcl
object({
  network = optional(object({
    cni = optional(object({
      name = string
      urls = optional(list(string))
    }))
    dnsDomain      = optional(string)
    podSubnets     = optional(list(string))
    serviceSubnets = optional(list(string))
  }))
  apiServer = optional(object({
    image     = string
    extraArgs = optional(map(string))
    extraVolumes = optional(list(object({
      hostPath  = string
      mountPath = string
      readonly  = bool
    })))
    env                      = optional(map(string))
    certSANs                 = optional(list(string))
    disablePodSecurityPolicy = optional(bool)
    admissionControl = optional(list(object({
      name          = string
      configuration = map(any)
    })))
  }))
  controllerManager = optional(object({
    image     = string
    extraArgs = optional(map(string))
    extraVolumes = optional(list(object({
      hostPath  = string
      mountPath = string
      readonly  = bool
    })))
    env = optional(map(string))
  }))
  proxy = optional(object({
    disabled  = bool
    image     = optional(string)
    mode      = optional(string)
    extraArgs = optional(map(string))
  }))
  scheduler = optional(object({
    image     = string
    extraArgs = optional(map(string))
    extraVolumes = optional(list(object({
      hostPath  = string
      mountPath = string
      readonly  = bool
    })))
    env = optional(map(string))
  }))
  etcd = optional(object({
    image     = optional(string)
    extraArgs = optional(map(string))
    subnet    = optional(string)
  }))
  coreDNS = optional(object({
    disabled = bool
    image    = optional(string)
  }))
  externalCloudProvider = optional(object({
    enabled   = bool
    manifests = list(string)
  }))
  adminKubeconfig = optional(object({
    certLifetime = string
  }))
  allowSchedulingOnMasters = optional(bool)
})
```

See [ClusterConfig](https://www.talos.dev/v1.0/reference/configuration/#clusterconfig) section in Talos Configuration Reference for detail description. 

### Cluster Inline Manifests Input

```hcl
list(object({
  name     = string
  contents = string
}))
```

See [ClusterConfig](https://www.talos.dev/v1.0/reference/configuration/#clusterconfig) section in Talos Configuration Reference for detail description.

## Outputs

| Name | Description | Type | Sensitive |
|---|---|---|---|
| default_ip_addresses | List of nodes IP addresses from VMTools by default. | `list(string)` | `false` |

## Authors

Module is maintained by [Ilya Pozdnov](https://github.com/ilpozzd).

## License

Apache 2 Licensed. See [LICENSE](LICENSE) for full details.
