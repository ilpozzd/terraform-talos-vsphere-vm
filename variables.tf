variable "datacenter" {
  description = "VMware datacenter name."
  type        = string
}

variable "datastores" {
  description = "VMWare datastore(s) where all data for the virtual machine will be placed in."
  type        = list(string)
}

variable "hosts" {
  description = "ESXi host(s) where the virtual machine will be created."
  type        = list(string)
}

variable "resource_pool" {
  description = "VMWare resource pool where the virtual machine will be created."
  type        = string
}

variable "folder" {
  description = "Folder to create the virtual machine in."
  type        = string
}

variable "remote_ovf_url" {
  description = "URL to the remote Talos OS 1.0.x ovf/ova file."
  type        = string
}

variable "vm_count" {
  description = "Number of virtual machines."
  type        = number
  default     = 1
}

variable "num_cpus" {
  description = "The total number of virtual processor cores to assign to the virtual machine."
  type        = number
  default     = 2
}

variable "memory" {
  description = "The amount of RAM for the virtual machine, in Mb."
  type        = number
  default     = 2048
}

variable "disks" {
  description = "A specification list for a virtual disk devices on the virtual machine. Use only first disk to Talos installation in 'machine_base_configuration' block"
  type = list(object({
    label            = string
    size             = number
    eagerly_scrub    = optional(bool)
    thin_provisioned = optional(bool)
  }))
}

variable "network_interfaces" {
  description = "A specification list for a virtual NIC on the virtual machine."
  type = list(object({
    name = string
  }))
}

variable "create_init_node" {
  description = "Whether to create an initialization node. If 'true', the first virtual machine will be the initialization node."
  type        = bool
  default     = false
}

variable "talos_base_configuration" {
  description = "Talos OS top-level configuration. See https://www.talos.dev/v1.0/reference/configuration/#config."
  type = object({
    version = string
    persist = bool
  })

  default = {
    version = "v1alpha1"
    persist = false
  }
}

variable "machine_secrets" {
  description = "Secret data that is used to create trust relationships between virtual machines. See https://www.talos.dev/v1.0/reference/configuration/#machineconfig."
  type = object({
    token = string
    ca = object({
      crt = string
      key = string
    })
  })
}

variable "talos_admin_pki" {
  description = "Base64 encoded certificate (signed by machine_secrets.ca.crt) and key (in ED25519) to provide access to virtual machine trought talosctl. Required if machine_type = 'controlplane' and create_init_node = 'true'."
  type = object({
    crt = optional(string)
    key = optional(string)
  })
  default = {}
}

variable "machine_base_configuration" {
  description = "Basic configuration of the virtual machine. See https://www.talos.dev/v1.0/reference/configuration/#machineconfig."
  type = object({
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
}

variable "machine_extra_configuration" {
  description = "Extended configuration of the virtual machine. See https://www.talos.dev/v1.0/reference/configuration/#machineconfig."
  type = object({
    controlPlane = optional(object({
      controllerManager = optional(object({
        disabled = bool
      }))
      scheduler = optional(object({
        disabled = bool
      }))
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
  default = {}
}

variable "machine_type" {
  description = "The role of the virtual machine in the Kubernetes cluster (controlplane or worker). See https://www.talos.dev/v1.0/reference/configuration/#machineconfig."
  type        = string
}

variable "machine_cert_sans" {
  description = "A list of alternative names of for *vm_count* virtual machines. See https://www.talos.dev/v1.0/reference/configuration/#machineconfig."
  type        = list(list(string))
  default     = []
}

variable "machine_network" {
  description = "General network configuration of the virtual machine. 'hostname' and 'interfaces' parameters are described in separate inputs. See https://www.talos.dev/v1.0/reference/configuration/#networkconfig."
  type = object({
    nameservers = optional(list(string))
    extraHostEntries = optional(list(object({
      ip      = string
      aliases = list(string)
    })))
    kubespan = optional(object({
      enabled = bool
    }))
  })
  default = {}
}

variable "machine_network_hostnames" {
  description = "A list of hostnames for *vm_count* virtual machines (if not set will be generated automaticly). See https://www.talos.dev/v1.0/reference/configuration/#networkconfig."
  type        = list(string)
  default     = []
}

variable "machine_network_interfaces" {
  description = "A list of network interfaces for *vm_count* virtual machines (if not set DHCP will be used). If machine_type = 'controlplane' and create_init_node = 'true', not less than one element with one static IP address required. See https://www.talos.dev/v1.0/reference/configuration/#device."
  type = list(list(object({
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
  default = []
}

variable "cluster_secrets" {
  description = "Secret data that is used to establish trust relationships between Kubernetes cluster nodes. See https://www.talos.dev/v1.0/reference/configuration/#clusterconfig."
  type = object({
    id     = string
    secret = string
    token  = string
    ca = object({
      crt = string
      key = string
    })
  })
}

variable "control_plane_cluster_secrets" {
  description = "Secret data required to establish trust relationships between components used by 'controlplane' nodes in the Kubernetes cluster. Required if machine_type = 'controlplane'. See https://www.talos.dev/v1.0/reference/configuration/#clusterconfig."
  type = object({
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
  default = {}
}

variable "cluster_name" {
  description = "The name of the cluster. See https://www.talos.dev/v1.0/reference/configuration/#clusterconfig."
  type        = string
}

variable "cluster_control_plane" {
  description = "Data to define the API endpoint address for joining a node to the Kubernetes cluster. Required if (create_init_node = 'false' or (create_init_node = 'true' and vm_count > '1')). See https://www.talos.dev/v1.0/reference/configuration/#controlplaneconfig."
  type = object({
    endpoint           = optional(string)
    localAPIServerPort = optional(number)
  })
}

variable "cluster_discovery" {
  description = "Data that sets up the discovery of nodes in the Kubernetes cluster. See https://www.talos.dev/v1.0/reference/configuration/#clusterdiscoveryconfig."
  type = object({
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
  default = {
    enabled = true
  }
}

variable "control_plane_cluster_configuration" {
  description = "Data that configure the components of the 'controlplane' nodes in the Kubernetes cluster. See https://www.talos.dev/v1.0/reference/configuration/#clusterconfig."
  type = object({
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
  default = {}
}

variable "cluster_inline_manifests" {
  description = "A list of Kuberenetes manifests whose content is represented as a string. These will get automatically deployed as part of the bootstrap. See https://www.talos.dev/v1.0/reference/configuration/#clusterconfig."
  type = list(object({
    name     = string
    contents = string
  }))
  default = []
}

variable "cluster_extra_manifests" {
  description = "A list of 'URLs' that point to additional manifests. These will get automatically deployed as part of the bootstrap. See https://www.talos.dev/v1.0/reference/configuration/#clusterconfig."
  type        = list(string)
  default     = []
}

variable "cluster_extra_manifest_headers" {
  description = "A map of key value pairs that will be added while fetching the 'cluster_extra_manifests'. See https://www.talos.dev/v1.0/reference/configuration/#clusterconfig."
  type        = map(string)
  default     = {}
}

variable "vmtoolsd_extra_manifest" {
  description = "A link to talos-vmtoolsd Kubernetes manifest."
  type        = string
  default     = "https://raw.githubusercontent.com/mologie/talos-vmtoolsd/release-0.3/deploy/0.3.yaml"
}
