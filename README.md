## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_password | Password of the VM admin account | `string` | `null` | no |
| admin\_username | Name of the VM admin account | `string` | n/a | yes |
| boot\_diagnostic | (Optional) | `bool` | `false` | no |
| cluster\_members | Config of each cluster member | `any` | n/a | yes |
| custom\_data | Specifies custom data to supply to the machine. On Linux-based systems, this can be used as a cloud-init script. On other systems, this will be copied as a file on disk. Internally, Terraform will base64 encode this value before sending it to the API. The maximum length of the binary array is 65535 bytes. | `string` | `null` | no |
| data\_disks | Map of object of disk sizes in gigabytes and lun number for each desired data disks. See variable.tf file for example | `any` | `{}` | no |
| data\_managed\_disk\_type | Specifies the type of Data Managed Disk which should be created. Possible values are Standard\_LRS or Premium\_LRS. | `string` | `"Standard_LRS"` | no |
| dependancyAgent | Should the VM be include the dependancy agent | `bool` | `false` | no |
| encryptDisks | Should the VM disks be encrypted. See option-30-AzureDiskEncryption.tf file for example | <pre>object({<br>    KeyVaultResourceId = string<br>    KeyVaultURL        = string<br>  })</pre> | `null` | no |
| env | 4 chars defining the environment name prefix for the VM. Example: ScSc | `string` | n/a | yes |
| lb | (Optional) Loadbalancer configuration for the HA VMs. | `any` | `null` | no |
| license\_type | (Optional) Specifies the BYOL Type for this Virtual Machine. Possible values are RHEL\_BYOS and SLES\_BYOS. | `string` | `null` | no |
| os\_managed\_disk\_type | Specifies the type of OS Managed Disk which should be created. Possible values are Standard\_LRS or Premium\_LRS. | `string` | `"Standard_LRS"` | no |
| plan | An optional plan block | <pre>object({<br>    name      = string<br>    product   = string<br>    publisher = string<br>  })</pre> | `null` | no |
| platform\_fault\_domain\_count | (Optional) Specifies the number of update domains that are used. Defaults to 5. Changing this forces a new resource to be created. | `string` | `"2"` | no |
| platform\_managed | (Optional) Specifies whether the availability set is managed or not. Possible values are true (to specify aligned) or false (to specify classic). | `bool` | `true` | no |
| platform\_update\_domain\_count | (Optional) Specifies the number of fault domains that are used. Defaults to 3. Changing this forces a new resource to be created. | `string` | `"3"` | no |
| priority | Specifies the priority of this Virtual Machine. Possible values are Regular and Spot. Defaults to Regular. Changing this forces a new resource to be created. | `string` | `"Regular"` | no |
| public\_ip | Should the VM be assigned public IP(s). True or false. | `bool` | `false` | no |
| resource\_group | Resourcegroup object that will contain the VM resources | `any` | n/a | yes |
| serverType | 3 chars server type code for the VM. | `string` | `"SRV"` | no |
| shutdownConfig | Should the VM shutdown at the time specified. See option-30-autoshutdown.tf file for example | <pre>object({<br>    autoShutdownStatus             = string<br>    autoShutdownTime               = string<br>    autoShutdownTimeZone           = string<br>    autoShutdownNotificationStatus = string<br>  })</pre> | `null` | no |
| storage\_image\_reference | This block provisions the Virtual Machine from one of two sources: an Azure Platform Image (e.g. Ubuntu/Windows Server) or a Custom Image. Refer to https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html for more details. | <pre>object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  })</pre> | <pre>{<br>  "offer": "RHEL",<br>  "publisher": "RedHat",<br>  "sku": "7.4",<br>  "version": "latest"<br>}</pre> | no |
| storage\_os\_disk | This block describe the parameters for the OS disk. Refer to https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine#os_disk for more details. | <pre>object({<br>    caching       = string<br>    create_option = string<br>    disk_size_gb  = number<br>  })</pre> | <pre>{<br>  "caching": "ReadWrite",<br>  "create_option": "FromImage",<br>  "disk_size_gb": null<br>}</pre> | no |
| subnet | subnet object to which the VM NIC will connect to | `any` | n/a | yes |
| tags | Tags that will be associated to VM resources | `map(string)` | <pre>{<br>  "exampleTag1": "SomeValue2"<br>}</pre> | no |
| ultra\_ssd\_enabled | Should the capacity to enable Data Disks of the UltraSSD\_LRS storage account type be supported on this Virtual Machine? | `bool` | `false` | no |
| userDefinedString | User defined portion of the server name. Up to 8 chars minus the postfix lenght | `string` | n/a | yes |
| vm\_size | Specifies the size of the Virtual Machine. Eg: Standard\_F4 | `string` | n/a | yes |
| zone | The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created. | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| VMs | The vm module object |
| availability\_set | The availability\_set object |

