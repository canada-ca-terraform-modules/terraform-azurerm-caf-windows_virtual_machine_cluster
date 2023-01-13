# Terraform Windows Cluster

## Introduction

This module deploys a Cluster of n Windows VMs  [virtual machine resource](https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/2019-03-01/virtualmachines) with an NSG, 1 NIC and a simple OS Disk.

## Security Controls

The following security controls can be met through configuration of this template:

* AC-1, AC-10, AC-11, AC-11(1), AC-12, AC-14, AC-16, AC-17, AC-18, AC-18(4), AC-2 , AC-2(5), AC-20(1) , AC-20(3), AC-20(4), AC-24(1), AC-24(11), AC-3, AC-3 , AC-3(1), AC-3(3), AC-3(9), AC-4, AC-4(14), AC-6, AC-6, AC-6(1), AC-6(10), AC-6(11), AC-7, AC-8, AC-8, AC-9, AC-9(1), AI-16, AU-2, AU-3, AU-3(1), AU-3(2), AU-4, AU-5, AU-5(3), AU-8(1), AU-9, CM-10, CM-11(2), CM-2(2), CM-2(4), CM-3, CM-3(1), CM-3(6), CM-5(1), CM-6, CM-6, CM-7, CM-7, IA-1, IA-2, IA-3, IA-4(1), IA-4(4), IA-5, IA-5, IA-5(1), IA-5(13), IA-5(1c), IA-5(6), IA-5(7), IA-9, SC-10, SC-13, SC-15, SC-18(4), SC-2, SC-2, SC-23, SC-28, SC-30(5), SC-5, SC-7, SC-7(10), SC-7(16), SC-7(8), SC-8, SC-8(1), SC-8(4), SI-14, SI-2(1), SI-3

## Dependancies

Hard:

* Resource Groups
* Keyvault
* VNET-Subnet

Optional (depending on options configured):

* log analytics workspace

## Example terraform code to use module

```hcl
variable "windows_VMs_cluster" {
  type    = any
  default = []
}

locals {
  windows_storage_image_reference_cluster = {
    publisher = "MicrosoftWindowsServer",
    offer     = "WindowsServer",
    sku       = "2019-Datacenter",
    version   = "latest",
  }
  deployListWindowsCluster = {
    for x in var.windows_VMs_cluster :
    "${x.serverType}-${x.userDefinedString}-HA" => x if(lookup(x, "deploy", true) != false)
  }
}

module "windows_VMs_cluster" {
  source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-windows_virtual_machine_cluster?ref=v1.0.0"
  # source   = "/home/bernard/azdo/modules/terraform-azurerm-caf-windows_virtual_machine_cluster"
  for_each = local.deployListWindowsCluster

  env                          = var.env
  serverType                   = each.value.serverType
  userDefinedString            = each.value.userDefinedString
  resource_group               = local.resource_groups_L2[each.value.resource_group]
  subnet                       = local.subnets[each.value.subnet]
  platform_fault_domain_count  = lookup(each.value, "platform_fault_domain_count", "2")
  platform_update_domain_count = lookup(each.value, "platform_update_domain_count", "3")
  public_ip                    = lookup(each.value, "public_ip", false)
  priority                     = lookup(each.value, "priority", "Regular")
  license_type                 = lookup(each.value, "license_type", null)
  admin_username               = lookup(each.value, "admin_username", "azureadmin")
  admin_password               = each.value.admin_password
  vm_size                      = each.value.vm_size
  boot_diagnostic              = try(each.value.boot_diagnostic, false)
  cluster_members              = each.value.cluster_members
  storage_image_reference      = lookup(each.value, "storage_image_reference", local.windows_storage_image_reference_cluster)
  storage_os_disk              = lookup(each.value, "storage_os_disk", null)
  os_managed_disk_type         = lookup(each.value, "os_managed_disk_type", null)
  plan                         = lookup(each.value, "plan", null)
  custom_data                  = lookup(each.value, "custom_data", false) != false ? base64encode(file(each.value.custom_data)) : null
  ultra_ssd_enabled            = lookup(each.value, "ultra_ssd_enabled", false)
  zone                         = lookup(each.value, "zone", null)
  data_disks                   = lookup(each.value, "data_disks", {})
  encryptDisks = lookup(each.value, "encryptDisks", false) != false ? {
    KeyVaultResourceId = local.Project-kv.id
    KeyVaultURL        = local.Project-kv.vault_uri
  } : null
  dependancyAgent = lookup(each.value, "dependancyAgent", false)
  shutdownConfig  = lookup(each.value, "shutdownConfig", null)
  lb              = lookup(each.value, "lb", null)
  tags            = lookup(each.value, "tags", null) == null ? var.tags : merge(var.tags, each.value.tags)
}
```

## Example tfvars config

```hcl
windows_VMs_cluster = [
  /*
  # Template for Linux server variables

  Server-Name = {
    deploy = bool # Optional. Default is true
    admin_username       = string # Optional. Default is "azureadmin" 
    admin_password       = string # Required
    os_managed_disk_type = string # Optional. Default is "StandardSSD_LRS"
    vm_size              = string # Required. Example: "Standard_D2s_v3"
    priority             = string # Optional. Default is "Regular". possible values are "Regular" or "Spot"
  }
  */

  {
    deploy            = true
    serverType        = "SWD"
    userDefinedString = "TMW"
    resource_group    = "Project"
    subnet            = "PAZ"
    platform_fault_domain_count = "2"   # Power falut range 1-3
    platform_update_domain_count = "3"  # Update range 1-5
    cluster_members = {
      "01" = {
        nic_ip_configuration = {
          private_ip_address            = ["10.1.114.5"]
          private_ip_address_allocation = ["Static"]
        }
      },
      "02" = {
        nic_ip_configuration = {
          private_ip_address            = ["10.1.114.6"]
          private_ip_address_allocation = ["Static"]
        }
      },
      "03" = {
        nic_ip_configuration = {
          private_ip_address            = ["10.1.114.7"]
          private_ip_address_allocation = ["Static"]
        }
      },
      # "4" = {
      #   nic_ip_configuration = {
      #     private_ip_address            = ["10.150.66.72"]
      #     private_ip_address_allocation = ["Static"]
      #   }
      # },
      # "5" = {
      #   nic_ip_configuration = {
      #     private_ip_address            = ["10.150.66.73"]
      #     private_ip_address_allocation = ["Static"]
      #   }
      # }
    }
    admin_username = "azureadmin"
    admin_password = "Canada123!"
    # custom_data             = "scripts/wsl2.ps1"
    vm_size  = "Standard_D8s_v3"
    priority = "Regular"
    storage_image_reference = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    }
    os_managed_disk_type = "Premium_LRS"
    storage_os_disk = {
      caching       = "ReadWrite"
      create_option = "FromImage"
      disk_size_gb  = null
    }
    data_disks = {
      # "data1disk" = {
      #   disk_size_gb         = 1024
      #   storage_account_type = "Premium_LRS"
      #   lun                  = 0
      # },
      # "backup" = {
      #   disk_size_gb         = 50
      #   storage_account_type = "Premium_LRS"
      #   lun                  = 1
      # }
    }
    encryptDisks = false
    lb = {
      private_ip_address_allocation = "Static" # Optional. Default to Static
      private_ip_address            = "10.1.114.4"
      sku                           = "Standard" # Optional. Default to Standard
      probes = {
        tcp443 = {
          port                = 443 # Port to probe to detect health of vm
          interval_in_seconds = 5   # Optional. Default to 5
        }
      }
      rules = {
        tcp443 = {
          protocol                = "Tcp"
          frontend_port           = 443
          backend_port            = 443
          probe_name              = "tcp443"
          load_distribution       = "SourceIPProtocol"
          enable_floating_ip      = false
          idle_timeout_in_minutes = 15
        }
      }
    }
  },
  {
    deploy            = true
    serverType        = "SWD"
    userDefinedString = "DMC"
    resource_group    = "Project"
    subnet            = "OZ"
    platform_fault_domain_count = "2"   # Power falut range 1-3
    platform_update_domain_count = "3"  # Update range 1-5
    cluster_members = {
      "01" = {
        nic_ip_configuration = {
          private_ip_address            = ["10.1.114.36"]
          private_ip_address_allocation = ["Static"]
        }
      },
      "02" = {
        nic_ip_configuration = {
          private_ip_address            = ["10.1.114.37"]
          private_ip_address_allocation = ["Static"]
        }
      },
      # "03" = {
      #   nic_ip_configuration = {
      #     private_ip_address            = ["10.1.114.7"]
      #     private_ip_address_allocation = ["Static"]
      #   }
      # },
      # "4" = {
      #   nic_ip_configuration = {
      #     private_ip_address            = ["10.150.66.72"]
      #     private_ip_address_allocation = ["Static"]
      #   }
      # },
      # "5" = {
      #   nic_ip_configuration = {
      #     private_ip_address            = ["10.150.66.73"]
      #     private_ip_address_allocation = ["Static"]
      #   }
      # }
    }
    admin_username = "azureadmin"
    admin_password = "Canada123!"
    # custom_data             = "scripts/wsl2.ps1"
    vm_size  = "Standard_D2s_v3"
    priority = "Regular"
    storage_image_reference = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    }
    os_managed_disk_type = "Premium_LRS"
    storage_os_disk = {
      caching       = "ReadWrite"
      create_option = "FromImage"
      disk_size_gb  = null
    }
    data_disks = {
      # "data1disk" = {
      #   disk_size_gb         = 1024
      #   storage_account_type = "Premium_LRS"
      #   lun                  = 0
      # },
      # "backup" = {
      #   disk_size_gb         = 50
      #   storage_account_type = "Premium_LRS"
      #   lun                  = 1
      # }
    }
    encryptDisks = false
    # lb = {
    #   private_ip_address_allocation = "Static" # Optional. Default to Static
    #   private_ip_address            = "10.1.114.4"
    #   sku                           = "Standard" # Optional. Default to Standard
    #   probes = {
    #     tcp443 = {
    #       port                = 443 # Port to probe to detect health of vm
    #       interval_in_seconds = 5   # Optional. Default to 5
    #     }
    #   }
    #   rules = {
    #     tcp443 = {
    #       protocol                = "Tcp"
    #       frontend_port           = 443
    #       backend_port            = 443
    #       probe_name              = "tcp443"
    #       load_distribution       = "SourceIPProtocol"
    #       enable_floating_ip      = false
    #       idle_timeout_in_minutes = 15
    #     }
    #   }
    # }
  },
]
```