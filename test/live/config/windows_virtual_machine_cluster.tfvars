# config/windows_virtual_machine_cluster.tfvars
# Tracked, ready-to-run fixture for the test/live harness - one representative
# real-usage instance, not a two-code-path engineered fixture.
#
# admin_password is a placeholder for throwaway test resources only.
#
# vm_size uses the Dav6 family (Standard_D2as_v6), not Dsv5/Dasv5 - the
# sandbox subscription's default Dsv5/Dasv5 family quota in canadacentral
# hits a hard Azure capacity restriction. Dav6 quota has already been
# provisioned on the sandbox specifically to avoid this.
#
# storage_image_reference.sku uses "2022-datacenter-g2" (Gen2), not the
# plain "2022-Datacenter" Gen1 SKU - Dav6-family sizes are Gen2-only VMs and
# reject a Gen1 image with "cannot boot Hypervisor Generation '1'".
#
# Single cluster member (not two) - live-test only needs to prove the
# module's common path applies cleanly; a second node doubles live sandbox
# spend/runtime without adding coverage for this gate.

env = "live"

admin_username = "azureadmin"
admin_password = "CHANGE-ME-P@ssw0rd1234!" # placeholder only - throwaway probe VM, destroyed after use

vm_size = "Standard_D2as_v6"

storage_image_reference = {
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2022-datacenter-g2"
  version   = "latest"
}

cluster_members = {
  nd1 = {
    nic_ip_configuration = {
      private_ip_address            = [null]
      private_ip_address_allocation = ["Dynamic"]
    }
  }
}

data_managed_disk_type = "Standard_LRS"

data_disks = {
  disk1 = {
    disk_size_gb = 32
    lun          = 0
  }
}
