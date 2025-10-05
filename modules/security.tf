#================================================
# AZURE FIREWALL
#================================================

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  count               = var.enable_firewall ? 1 : 0
  name                = "pip-${local.resource_prefix}-afw-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Azure Firewall Policy
resource "azurerm_firewall_policy" "main" {
  count               = var.enable_firewall ? 1 : 0
  name                = "afwp-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = local.common_tags

  dns {
    proxy_enabled = true
  }

  threat_intelligence_mode = "Alert"
}

# Firewall Policy Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "main" {
  count              = var.enable_firewall ? 1 : 0
  name               = "DefaultRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.main[0].id
  priority           = 500

  # Application Rules
  application_rule_collection {
    name     = "AllowWebTraffic"
    priority = 500
    action   = "Allow"

    rule {
      name = "AllowHTTPSOutbound"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses = ["10.0.0.0/8"]
      destination_fqdns = [
        "*.microsoft.com",
        "*.azure.com",
        "*.windows.net",
        "*.ubuntu.com",
        "security.ubuntu.com"
      ]
    }

    rule {
      name = "AllowWindowsUpdate"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses = ["10.0.0.0/8"]
      destination_fqdns = [
        "*.windowsupdate.microsoft.com",
        "*.update.microsoft.com",
        "*.windowsupdate.com",
        "download.microsoft.com"
      ]
    }
  }

  # Network Rules
  network_rule_collection {
    name     = "AllowInternalTraffic"
    priority = 400
    action   = "Allow"

    rule {
      name                  = "AllowSpokeToSpoke"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
      destination_addresses = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
      destination_ports     = ["*"]
    }

    rule {
      name                  = "AllowSpokeToHub"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
      destination_addresses = ["10.0.0.0/16"]
      destination_ports     = ["53", "80", "443", "3389", "22"]
    }

    rule {
      name                  = "AllowDNS"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
    }
  }

  # DNAT Rules for inbound access
  nat_rule_collection {
    name     = "InboundNATRules"
    priority = 300
    action   = "Dnat"

    rule {
      name                = "RDPToSpoke1VM"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.firewall[0].ip_address
      destination_ports   = ["3389"]
      translated_address  = "10.1.4.10"
      translated_port     = "3389"
    }
  }
}

## Azure Firewall
resource "azurerm_firewall" "main" {
  count               = var.enable_firewall ? 1 : 0
  name                = "afw-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.main[0].id
  tags                = local.common_tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

#================================================
# AZURE BASTION
#================================================

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "pip-${local.resource_prefix}-bastion-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  count               = var.enable_bastion ? 1 : 0
  name                = "bastion-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}
