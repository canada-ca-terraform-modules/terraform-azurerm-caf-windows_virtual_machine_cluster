variable "env" {
  description = "4 chars environment prefix used in the generated VM names"
  type        = string
  default     = "live"
}

variable "location" {
  description = "Location for the throwaway live-test resource group/vnet/subnet"
  type        = string
  default     = "canadacentral"
}

variable "tags" {
  description = "Tags applied to every resource this harness creates"
  type        = map(string)
  default = {
    purpose = "module-live-test"
  }
}

variable "pr_number" {
  description = <<-EOT
    Suffix applied to test_dependencies.tf resource names so concurrent PRs
    against this module never collide on the same sandbox subscription. CI
    sources this from `TF_VAR_pr_number` (`github.event.number`); manual runs
    can leave the default or pass their own value.
  EOT
  type        = string
  default     = "manual"
}

variable "repository" {
  description = "This repo's own org/name slug - tags the live-test resource group so the shared-subscription sweeper only ever matches this repo's own PRs"
  type        = string
  default     = "canada-ca-terraform-modules/terraform-azurerm-caf-windows_virtual_machine_cluster"
}

variable "admin_username" {
  description = "Name of the VM admin account"
  type        = string
}

variable "admin_password" {
  description = "Password of the VM admin account"
  type        = string
  default     = null
  sensitive   = true
}

variable "vm_size" {
  description = "Specifies the size of the Virtual Machine. Eg: Standard_D2as_v6"
  type        = string
}

variable "storage_image_reference" {
  description = "Source image reference for the cluster members"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
}

variable "cluster_members" {
  description = "Config of each cluster member, passed straight through to the module"
  type        = any
}

variable "data_managed_disk_type" {
  description = "Specifies the type of Data Managed Disk which should be created."
  type        = string
  default     = "Standard_LRS"
}

variable "data_disks" {
  description = "Map of data disk objects, passed straight through to the module"
  type        = any
  default     = {}
}

variable "lb" {
  description = "(Optional) Loadbalancer configuration for the HA VMs, passed straight through to the module"
  type        = any
  default     = null
}
