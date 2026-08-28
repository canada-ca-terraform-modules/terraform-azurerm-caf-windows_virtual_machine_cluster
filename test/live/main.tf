terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }

  # Empty on purpose: the state file path is supplied at `terraform init`
  # time via `-backend-config="path=..."` (partial configuration), so the
  # target-branch checkout and the PR-branch checkout can point at the same
  # external state file without either owning its own local state.
  backend "local" {}
}

provider "azurerm" {
  storage_use_azuread             = true
  resource_provider_registrations = "legacy"
  features {}
}

module "windows_virtual_machine_cluster" {
  # PR code and baseline code are two on-disk checkouts of this same repo,
  # not two resolved git refs - no pinned ?ref, no version toggle here.
  source = "../../"

  env                     = var.env
  userDefinedString       = "livetst"
  resource_group          = local.resource_group # from test_dependencies.tf
  subnet                  = local.subnet         # from test_dependencies.tf
  cluster_members         = var.cluster_members
  admin_username          = var.admin_username
  admin_password          = var.admin_password
  vm_size                 = var.vm_size
  storage_image_reference = var.storage_image_reference
  data_managed_disk_type  = var.data_managed_disk_type
  data_disks              = var.data_disks
  lb                      = var.lb
  tags                    = var.tags
}
