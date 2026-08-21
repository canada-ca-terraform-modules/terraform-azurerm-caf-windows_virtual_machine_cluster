# ESLZ/windows_virtual_machine_cluster.tfvars
# Example tfvars for the ESLZ/windows_virtual_machine_cluster.tf module block.
# Rules: existing entries unchanged; new args go below, commented out with explanation.

windows_virtual_machine_clusters = {
  # --- EXISTING ENTRY (minimal, backward compatible) ---
  SRV-APPHA1 = {
    env                = "Prod"
    userDefinedString  = "apphacluster"
    resource_group_key = "Project"
    subnet_key         = "app"
    admin_username     = "azureadmin"
    # admin_password: sensitive - supply via TF_VAR_windows_virtual_machine_clusters or a secrets store
    vm_size = "Standard_D2s_v5"

    cluster_members = {
      node1 = {
        nic_ip_configuration = {
          private_ip_address            = [null]
          private_ip_address_allocation = ["Dynamic"]
        }
      }
      node2 = {
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

  # --- NEW ARGUMENT EXAMPLES (commented out) ---
  # SRV-APPHA2 = {
  #   env                = "Prod"
  #   userDefinedString  = "apphacluster2"
  #   resource_group_key = "Project"
  #   subnet_key         = "app"
  #   admin_username     = "azureadmin"
  #   vm_size            = "Standard_D2s_v5"
  #
  #   cluster_members = {
  #     node1 = {
  #       nic_ip_configuration = {
  #         private_ip_address            = [null]
  #         private_ip_address_allocation = ["Dynamic"]
  #       }
  #     }
  #   }
  #
  #   # Networking: disable NIC-level NSG
  #   use_nic_nsg = false
  #
  #   # Windows patching
  #   cluster_enable_automatic_updates = true
  #   cluster_patch_mode               = "AutomaticByOS"
  #   cluster_patch_assessment_mode    = "ImageDefault"
  #
  #   # Pattern 12: pin an already-deployed availability set name
  #   # as_name = "existing-prod-as"
  #
  #   # Pattern 12: pin already-deployed loadbalancer resource names
  #   lb = {
  #     # lb_name           = "existing-prod-lb"
  #     # frontend_name     = "existing-prod-lb-fe"
  #     # backend_pool_name = "existing-prod-lb-bp"
  #     private_ip_address = "10.10.20.10"
  #     probes = {
  #       tcp443 = {
  #         # name = "existing-prod-probe"
  #         port = 443
  #       }
  #     }
  #     rules = {
  #       tcp443 = {
  #         # name                = "existing-prod-rule"
  #         protocol            = "Tcp"
  #         frontend_port       = 443
  #         backend_port        = 443
  #         probe_name          = "tcp443"
  #         load_distribution   = "SourceIPProtocol"
  #         enable_floating_ip  = true
  #         enable_tcp_reset    = true
  #       }
  #     }
  #   }
  # }
}
