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

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_VMs"></a> [VMs](#module\_VMs) | github.com/canada-ca-terraform-modules/terraform-azurerm-caf-windows_virtual_machine | v3.0.4 |

## Resources

| Name | Type |
|------|------|
| [azurerm_availability_set.availability_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_lb.loadbalancer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.loadbalancer-lbbp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_probe.loadbalancer-lbhp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.loadbalancer-lbr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_network_interface_backend_address_pool_association.LB_VMs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Password of the VM admin account | `string` | `null` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Name of the VM admin account | `string` | n/a | yes |
| <a name="input_boot_diagnostic"></a> [boot\_diagnostic](#input\_boot\_diagnostic) | (Optional) | `bool` | `false` | no |
| <a name="input_cluster_members"></a> [cluster\_members](#input\_cluster\_members) | Config of each cluster member | `any` | n/a | yes |
| <a name="input_custom_data"></a> [custom\_data](#input\_custom\_data) | Specifies custom data to supply to the machine. On Linux-based systems, this can be used as a cloud-init script. On other systems, this will be copied as a file on disk. Internally, Terraform will base64 encode this value before sending it to the API. The maximum length of the binary array is 65535 bytes. | `string` | `null` | no |
| <a name="input_data_disks"></a> [data\_disks](#input\_data\_disks) | Map of object of disk sizes in gigabytes and lun number for each desired data disks. See variable.tf file for example | `any` | `{}` | no |
| <a name="input_data_managed_disk_type"></a> [data\_managed\_disk\_type](#input\_data\_managed\_disk\_type) | Specifies the type of Data Managed Disk which should be created. Possible values are Standard\_LRS or Premium\_LRS. | `string` | `"Standard_LRS"` | no |
| <a name="input_dependancyAgent"></a> [dependancyAgent](#input\_dependancyAgent) | Should the VM be include the dependancy agent | `bool` | `false` | no |
| <a name="input_encryptDisks"></a> [encryptDisks](#input\_encryptDisks) | Should the VM disks be encrypted. See option-30-AzureDiskEncryption.tf file for example | <pre>object({<br>    KeyVaultResourceId = string<br>    KeyVaultURL        = string<br>  })</pre> | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | 4 chars defining the environment name prefix for the VM. Example: ScSc | `string` | n/a | yes |
| <a name="input_lb"></a> [lb](#input\_lb) | (Optional) Loadbalancer configuration for the HA VMs. | `any` | `null` | no |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | (Optional) Specifies the BYOL Type for this Virtual Machine. Possible values are RHEL\_BYOS and SLES\_BYOS. | `string` | `null` | no |
| <a name="input_os_managed_disk_type"></a> [os\_managed\_disk\_type](#input\_os\_managed\_disk\_type) | Specifies the type of OS Managed Disk which should be created. Possible values are Standard\_LRS or Premium\_LRS. | `string` | `"Standard_LRS"` | no |
| <a name="input_plan"></a> [plan](#input\_plan) | An optional plan block | <pre>object({<br>    name      = string<br>    product   = string<br>    publisher = string<br>  })</pre> | `null` | no |
| <a name="input_platform_fault_domain_count"></a> [platform\_fault\_domain\_count](#input\_platform\_fault\_domain\_count) | (Optional) Specifies the number of update domains that are used. Defaults to 5. Changing this forces a new resource to be created. | `string` | `"2"` | no |
| <a name="input_platform_managed"></a> [platform\_managed](#input\_platform\_managed) | (Optional) Specifies whether the availability set is managed or not. Possible values are true (to specify aligned) or false (to specify classic). | `bool` | `true` | no |
| <a name="input_platform_update_domain_count"></a> [platform\_update\_domain\_count](#input\_platform\_update\_domain\_count) | (Optional) Specifies the number of fault domains that are used. Defaults to 3. Changing this forces a new resource to be created. | `string` | `"3"` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | Specifies the priority of this Virtual Machine. Possible values are Regular and Spot. Defaults to Regular. Changing this forces a new resource to be created. | `string` | `"Regular"` | no |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | Should the VM be assigned public IP(s). True or false. | `bool` | `false` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Resourcegroup object that will contain the VM resources | `any` | n/a | yes |
| <a name="input_serverType"></a> [serverType](#input\_serverType) | 3 chars server type code for the VM. | `string` | `"SRV"` | no |
| <a name="input_shutdownConfig"></a> [shutdownConfig](#input\_shutdownConfig) | Should the VM shutdown at the time specified. See option-30-autoshutdown.tf file for example | <pre>object({<br>    autoShutdownStatus             = string<br>    autoShutdownTime               = string<br>    autoShutdownTimeZone           = string<br>    autoShutdownNotificationStatus = string<br>  })</pre> | `null` | no |
| <a name="input_storage_image_reference"></a> [storage\_image\_reference](#input\_storage\_image\_reference) | This block provisions the Virtual Machine from one of two sources: an Azure Platform Image (e.g. Ubuntu/Windows Server) or a Custom Image. Refer to https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html for more details. | <pre>object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  })</pre> | <pre>{<br>  "offer": "RHEL",<br>  "publisher": "RedHat",<br>  "sku": "7.4",<br>  "version": "latest"<br>}</pre> | no |
| <a name="input_storage_os_disk"></a> [storage\_os\_disk](#input\_storage\_os\_disk) | This block describe the parameters for the OS disk. Refer to https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine#os_disk for more details. | <pre>object({<br>    caching       = string<br>    create_option = string<br>    disk_size_gb  = number<br>  })</pre> | <pre>{<br>  "caching": "ReadWrite",<br>  "create_option": "FromImage",<br>  "disk_size_gb": null<br>}</pre> | no |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | subnet object to which the VM NIC will connect to | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags that will be associated to VM resources | `map(string)` | <pre>{<br>  "exampleTag1": "SomeValue2"<br>}</pre> | no |
| <a name="input_ultra_ssd_enabled"></a> [ultra\_ssd\_enabled](#input\_ultra\_ssd\_enabled) | Should the capacity to enable Data Disks of the UltraSSD\_LRS storage account type be supported on this Virtual Machine? | `bool` | `false` | no |
| <a name="input_userDefinedString"></a> [userDefinedString](#input\_userDefinedString) | User defined portion of the server name. Up to 8 chars minus the postfix lenght | `string` | n/a | yes |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | Specifies the size of the Virtual Machine. Eg: Standard\_F4 | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created. | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_VMs"></a> [VMs](#output\_VMs) | The vm module object |
| <a name="output_availability_set"></a> [availability\_set](#output\_availability\_set) | The availability\_set object |
