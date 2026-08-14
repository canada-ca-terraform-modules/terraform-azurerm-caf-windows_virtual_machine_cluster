# Changelog

All notable changes to this module are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## v2.0.0 - 2026-08-14

### Added

- `providers.tf` pinning `azurerm ~> 5.0` (`required_version >= 1.9`) - none existed before this upgrade.
- Pass-through variables for the child `windows_virtual_machine` module's arguments: `use_nic_nsg`, `data_managed_disk_type` (previously declared but never wired).
- Pattern 12 name overrides:
  - `as_name` (top-level) overrides the auto-generated availability set name.
  - `lb.lb_name`, `lb.frontend_name`, `lb.backend_pool_name` override the auto-generated loadbalancer/frontend/backend-pool names; per-probe/per-rule `name` key overrides each probe/rule name.
- `.tflint.hcl` (`call_module_type = "local"`), `.gitattributes` (`eol=lf`), `.github/workflows/terraform-ci.yml`, `.github/workflows/documentation.yml`, `.github/workflows/release.yml`, `tests/*.tftest.hcl`.
- `sensitive = true` on the `VMs` and `availability_set` outputs (both expose full resource/module objects).
- `ESLZ/windows_virtual_machine_cluster.tf` + `ESLZ/windows_virtual_machine_cluster.tfvars` - the module block and commented example L2 callers copy into their blueprint (for_each over `windows_virtual_machine_clusters`, looking up `resource_groups`/`subnets` by key). `ESLZ/.tflint.hcl` disables `terraform_required_version`/`terraform_required_providers` for that directory only.

### Changed

- Bumped the child module `terraform-azurerm-caf-windows_virtual_machine` pin from `v3.0.14` to `v3.1.0` (already upgraded to `azurerm ~> 5.0`).
- `azurerm_lb_rule`: renamed resource arguments `enable_floating_ip` -> `floating_ip_enabled` and `enable_tcp_reset` -> `tcp_reset_enabled` (azurerm v5 rename). Caller-facing tfvars keys (`each.value.enable_floating_ip` / `each.value.enable_tcp_reset` inside `lb.rules`) are unchanged - zero caller-facing impact.
- `.gitignore` replaced with the standard template (previously scoped only to a stale `test/` subdirectory).
- `storage_image_reference` default changed from RHEL 7.4 to Windows Server 2022 Datacenter (matches this module's purpose).

### Fixed

- `tags` default value had a duplicate `"exampleTag1"` map key (second entry silently overwrote the first); corrected to `"exampleTag2"`.
- `data_managed_disk_type` variable was declared but never wired to the child VM module (silently had no effect); now passed through as `data_managed_disk_type` on the `VMs` module block.
- `admin_password` variable marked `sensitive = true` (was previously plaintext-visible in plan/apply output).
- `azurerm_lb_rule`'s `floating_ip_enabled`/`tcp_reset_enabled` now read via `try(..., null)` instead of a bare `each.value.*` reference, so a caller's `lb.rules.*` entry omitting either key no longer crashes the plan.
- `platform_fault_domain_count`/`platform_update_domain_count` retyped from `string` to `number` (defaults `2`/`3`) to match the provider schema and remove reliance on implicit string-to-number coercion.

### Notes

- This module now adopts the `ESLZ/<resource>.tf` wrapper convention (`ESLZ/windows_virtual_machine_cluster.tf`). `release.yml` sources its version from that file's own `?ref=vX.Y.Z`.
- Major version bump (not minor) because this upgrade adds the module's first `required_providers`/`required_version` floor - the first hard version constraint can break a consumer's existing Terraform/provider install even though no resource argument itself broke compatibility.
- No backward-compat breaks: every existing `cluster_members`/`lb` tfvars shape continues to produce the same plan.
- The child `windows_virtual_machine` module (v3.1.0) does not yet expose `identity`, `secure_boot_enabled`, `vtpm_enabled`, `user_data`, `public_ip_zones`, or per-instance name overrides (`vm_name`, `nic_name`, etc.) - unlike its linux sibling. These will be available when the child module adds them in a future release.
