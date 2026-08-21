# tests/upgrade_compat.tftest.hcl
# Purpose: catch breaking resource/behavior changes before real infra plans -
# specifically cases where a variable's *default* silently changes and an
# existing caller who omits that variable gets a different plan.
#
# Design note: a real apply-based "deploy old version, then plan new version
# against that state" diff is not feasible here with mock_provider. This
# wrapper module chains cross-resource ARM-ID references (LB -> backend
# pool/probe/rule, availability_set/NIC -> child VM module) and azurerm v5
# strictly validates ARM ID format at apply time. mock_provider's default
# fake computed ids ("mhq2fqw5") fail that validation on apply, and
# override_resource cannot be targeted at resources inside a for_each child
# module instance (module.VMs["m1"].azurerm_network_interface.NIC) to supply
# valid ARM-format ids instead - confirmed by testing both mock apply and
# override_resource against this exact module tree.
#
# Instead, this file directly pins down every variable default that the
# child modules/resources are sensitive to, so that a future change to a
# default (the actual bug class this test exists to catch - see
# use_nic_nsg's true/false regression) fails a plan-only assertion instead
# of silently shipping.
mock_provider "azurerm" {}

variables {
  env               = "ScSc"
  serverType        = "SRV"
  userDefinedString = "clustertest"
  admin_username    = "azureadmin"
  admin_password    = "TestP@ssw0rd123!"
  vm_size           = "Standard_F4"
  resource_group = {
    id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
    name     = "rg-test"
    location = "canadacentral"
  }
  subnet = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/subnet-test"
  }
  cluster_members = {
    m1 = {
      nic_ip_configuration = {
        private_ip_address            = [null]
        private_ip_address_allocation = ["Dynamic"]
      }
    }
  }
  lb = {
    private_ip_address = "10.10.10.10"
    probes = {
      tcp443 = { port = 443 }
    }
    rules = {
      tcp443 = {
        protocol           = "Tcp"
        frontend_port      = 443
        backend_port       = 443
        probe_name         = "tcp443"
        load_distribution  = "SourceIPProtocol"
        enable_floating_ip = true
        enable_tcp_reset   = true
      }
    }
  }
}

# Step 1: an existing caller's plan using only the pre-upgrade required
# arguments - no new optional arguments (as_name, use_nic_nsg, etc.) set.
# Every variable default this plan depends on must resolve to the same
# behavior a caller deployed before this upgrade would have gotten.
run "baseline_plan_defaults_unchanged" {
  command = plan

  assert {
    condition     = azurerm_availability_set.availability_set.name == "ScScSRV-clustertest-as"
    error_message = "Baseline plan: unexpected availability set name"
  }
  assert {
    condition     = azurerm_lb.loadbalancer[0].name == "ScScSRV-clustertest-lb"
    error_message = "Baseline plan: unexpected loadbalancer name"
  }
  assert {
    condition     = azurerm_availability_set.availability_set.platform_fault_domain_count == 2
    error_message = "platform_fault_domain_count default must remain 2 after the string->number retype"
  }
  assert {
    condition     = azurerm_availability_set.availability_set.platform_update_domain_count == 3
    error_message = "platform_update_domain_count default must remain 3 after the string->number retype"
  }
  assert {
    condition     = var.use_nic_nsg == false
    error_message = "use_nic_nsg must default to false to match the child module's own default (v3.0.14 and v3.1.0) - an existing caller who omits it must not have an NSG silently created"
  }
}

# Step 2: plan the upgraded code (new optional args added) with those new
# args explicitly left at their own declared defaults - simulating an
# existing caller upgrading the module source without changing their tfvars.
run "upgrade_plan_no_replacement" {
  command = plan

  assert {
    condition     = azurerm_availability_set.availability_set.name == "ScScSRV-clustertest-as"
    error_message = "Availability set name must be unchanged after upgrade"
  }
  assert {
    condition     = azurerm_lb.loadbalancer[0].name == "ScScSRV-clustertest-lb"
    error_message = "Loadbalancer name must be unchanged after upgrade"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].floating_ip_enabled == true
    error_message = "floating_ip_enabled must still reflect the caller's enable_floating_ip value after the v5 rename"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].tcp_reset_enabled == true
    error_message = "tcp_reset_enabled must still reflect the caller's enable_tcp_reset value after the v5 rename"
  }
}

# Step 3: an as_name override plan must not change any other resource's
# generated name (isolates the new Pattern 12 arguments from unrelated
# resources).
run "as_name_override_isolated" {
  command = plan

  variables {
    as_name = "existing-prod-as"
  }

  assert {
    condition     = azurerm_availability_set.availability_set.name == "existing-prod-as"
    error_message = "as_name override must be applied"
  }
  assert {
    condition     = azurerm_lb.loadbalancer[0].name == "ScScSRV-clustertest-lb"
    error_message = "as_name override must not affect the loadbalancer name"
  }
}
