# test_dependencies.tf
# Self-contained dependency resources, owned entirely by this harness.
#
# Deliberately NOT reusing any shared/production resource group or upstream
# resource: writing into a shared RG (e.g. an L1-managed "Network" RG)
# usually requires elevated, non-sandbox permissions. A dedicated throwaway
# RG + vnet + subnet here needs only Contributor on the sandbox subscription
# and can never collide with or affect any production resource.
#
# windows_virtual_machine_cluster needs both `resource_group` (an object with
# name + location + id) and `subnet` (an object with an id) - it always
# creates a NIC per cluster member.

resource "azurerm_resource_group" "live_test" {
  # PR-number suffix keeps two concurrently open PRs against this module from
  # colliding on the same sandbox resource group (or, via the child module's
  # resource_group.id-derived naming, the same VM name).
  name     = "${var.env}-caf-winvmcluster-live-test-${var.pr_number}-rg"
  location = var.location

  # pr-number tag (ticket 13): lets the nightly orphan sweeper find this RG
  # by tag and match it back to a PR, independent of naming convention.
  # repository tag: the sandbox subscription is shared across module repos
  # (ticket 03), so the sweeper must scope its `pr-number` matches to only
  # this repo's own PRs.
  tags = merge(var.tags, {
    "pr-number"  = var.pr_number
    "repository" = var.repository
  })
}

resource "azurerm_virtual_network" "live_test" {
  name                = "${var.env}-caf-winvmcluster-live-test-${var.pr_number}-vnet"
  address_space       = ["10.253.0.0/16"] # arbitrary, unpeered - collision-safe by construction
  location            = azurerm_resource_group.live_test.location
  resource_group_name = azurerm_resource_group.live_test.name
  tags                = var.tags
}

resource "azurerm_subnet" "live_test" {
  name                 = "live-test-subnet"
  resource_group_name  = azurerm_resource_group.live_test.name
  virtual_network_name = azurerm_virtual_network.live_test.name
  address_prefixes     = ["10.253.0.0/24"]
}

locals {
  # The child windows_virtual_machine module computes a unique suffix via
  # substr(sha1(var.resource_group.id), 0, 8) - so .id must be present in
  # addition to .name and .location.
  resource_group = {
    id       = azurerm_resource_group.live_test.id
    name     = azurerm_resource_group.live_test.name
    location = azurerm_resource_group.live_test.location
  }
  subnet = { id = azurerm_subnet.live_test.id }
}
