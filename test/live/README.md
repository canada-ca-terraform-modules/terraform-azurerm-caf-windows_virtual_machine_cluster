# `test/live/` - live-test harness

A live, real-Azure-resource harness used by the `live-test` PR check (see
the [`live-test-actions`](https://github.com/canada-ca-terraform-modules/live-test-actions)
repo and this module's own `.github/workflows/live-test.yml` once it lands)
to prove that an open PR doesn't destroy or replace a resource a real
consumer already has running. It is **not** a substitute for either of the
module's other two test surfaces:

- **`tests/*.tftest.hcl`** - mock-based unit tests (`terraform test`, no
  provider credentials, no live Azure resources). Covers naming, defaults,
  and validation logic on every PR via `terraform-ci.yml`. Run these first;
  they're fast and free.
- **`ESLZ/`** - a usage example showing the map-based (`for_each`) blueprint
  pattern consumers actually wire this module into. Not exercised by CI at
  all; documentation only.
- **`test/live/`** (this directory) - a single, real instance of the module
  applied against a disposable Azure sandbox subscription. Used by CI to
  diff the PR's plan against a live baseline, and can be run manually by a
  maintainer the same way.

## What's here

| File | Purpose |
|---|---|
| `main.tf` | Module block with `source = "../../"` (a relative path, not a pinned `?ref` - "baseline" and "PR" are just two on-disk checkouts of this repo), the `azurerm` provider config, and an empty `backend "local" {}` block (path supplied at `init` time - see below). |
| `test_dependencies.tf` | A dedicated, throwaway resource group + vnet + subnet this harness owns outright - never a shared/production resource. Names are suffixed with `var.pr_number` so concurrently open PRs never collide. |
| `variables.tf` | `env`, `location` (defaults to `canadacentral`), `tags`, `pr_number` (defaults to `"manual"`), `repository`, plus the module's own required inputs (`admin_username`, `admin_password`, `vm_size`, `storage_image_reference`, `cluster_members`, `data_managed_disk_type`, `data_disks`, `lb`). |
| `config/windows_virtual_machine_cluster.tfvars` | One representative real-usage fixture: single cluster member, `Standard_D2as_v6` (Dav6 family - see below), one data disk. |

No Terragrunt anywhere under this directory - a single harness per repo has
no cross-harness DRY need.

## Module-specific notes

- `vm_size` uses the `Dav6` family (`Standard_D2as_v6`), not `Dsv5`/`Dasv5` -
  the sandbox subscription's default family quota in `canadacentral` hits a
  hard Azure capacity restriction on those families. `Dav6` quota has already
  been provisioned on the sandbox specifically to avoid this.
- Only one cluster member is exercised here (not a multi-node cluster) -
  live-test only needs to prove the module's common path applies cleanly;
  a second node would double live sandbox spend/runtime with no added
  coverage for this gate. The `tests/cluster.tftest.hcl` mock suite already
  covers the multi-member `for_each` path.

## Running it manually

Requires your own `az login` session against the sandbox subscription (CI
uses OIDC instead).

```bash
cd test/live
terraform init
terraform plan  -var-file=config/windows_virtual_machine_cluster.tfvars
terraform apply -var-file=config/windows_virtual_machine_cluster.tfvars
```

Confirm only the live-test resource group/vnet/subnet and
`module.windows_virtual_machine_cluster` are planned/applied, then tear it
down:

```bash
terraform destroy -var-file=config/windows_virtual_machine_cluster.tfvars
```

No `.tfstate` file is ever committed under `test/live/` - every run is
fully ephemeral, whether run by CI or by hand.

## Two-checkout state isolation (baseline vs. PR)

CI proves a PR isn't a breaking change by applying the target branch as a
live baseline, then plan/apply-ing the PR branch's checkout of this same
harness against that same live state - two on-disk checkouts of this repo,
one shared external state file, no state copying between them:

```bash
# Directory A: PR branch checkout, directory B: target branch checkout.
STATE=$RUNNER_TEMP/live-test-<pr-number>.tfstate

# 1. Baseline apply, from B.
cd B/test/live
terraform init -backend-config="path=$STATE"
terraform apply -var-file=config/windows_virtual_machine_cluster.tfvars -var="pr_number=<pr-number>"

# 2. PR plan (and, in CI, apply), from A, against the same state file.
cd A/test/live
terraform init -backend-config="path=$STATE"
terraform plan -var-file=config/windows_virtual_machine_cluster.tfvars -var="pr_number=<pr-number>"

# 3. Always tear down from A once the run finishes (`if: always()` in CI).
terraform destroy -var-file=config/windows_virtual_machine_cluster.tfvars -var="pr_number=<pr-number>"
```

`pr_number` (`TF_VAR_pr_number` in CI, sourced from `github.event.number`)
suffixes every `test_dependencies.tf` resource name, so two concurrently
open PRs against this module - each pointed at their own
`live-test-<pr-number>.tfstate` - never collide on the same sandbox resource
group. The module's own VM naming derives from `sha1(resource_group.id)`, so
a distinct per-PR resource group also yields a distinct per-PR VM name with
no further changes needed.
