#================================================
# DEVOPS SERVICES
#================================================

# Azure DevOps Project (if using Azure DevOps Services)
# Note: This requires the azuredevops provider, but we'll use alternative resources

# Container Registry for DevOps artifacts
resource "azurerm_container_registry" "devops" {
  count               = var.enable_devops ? 1 : 0
  name                = "acr${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}devops${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku                 = "Premium"
  admin_enabled       = false

  # Security settings
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"

  tags = local.common_tags
}

# Storage Account for DevOps artifacts
resource "azurerm_storage_account" "devops" {
  count                    = var.enable_devops ? 1 : 0
  name                     = "st${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}devops${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.spokes[0].name
  location                 = azurerm_resource_group.spokes[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security settings
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  tags = local.common_tags
}

# Key Vault for DevOps secrets
resource "azurerm_key_vault" "devops" {
  count                      = var.enable_devops ? 1 : 0
  name                       = "kv-${local.resource_prefix}-devops-${format("%03d", 1)}"
  location                   = azurerm_resource_group.spokes[0].location
  resource_group_name        = azurerm_resource_group.spokes[0].name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Security settings
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}

# Application Configuration for feature flags
resource "azurerm_app_configuration" "devops" {
  count               = var.enable_devops ? 1 : 0
  name                = "appcs-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku                 = "standard"

  # Security settings
  public_network_access_enabled = false

  tags = local.common_tags
}

# Service Bus for DevOps messaging
resource "azurerm_servicebus_namespace" "devops" {
  count               = var.enable_devops ? 1 : 0
  name                = "sb-${local.resource_prefix}-devops-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku                 = "Standard"

  # Security settings
  public_network_access_enabled = false

  tags = local.common_tags
}

# Service Bus Queue for build notifications
resource "azurerm_servicebus_queue" "build_notifications" {
  count        = var.enable_devops ? 1 : 0
  name         = "build-notifications"
  namespace_id = azurerm_servicebus_namespace.devops[0].id

  enable_partitioning = false
}

# Private Endpoints for DevOps Services
resource "azurerm_private_endpoint" "devops_acr" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-devops-acr-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-devops-acr"
    private_connection_resource_id = azurerm_container_registry.devops[0].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "devops_storage" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-devops-st-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-devops-storage"
    private_connection_resource_id = azurerm_storage_account.devops[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "devops_keyvault" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-devops-kv-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-devops-keyvault"
    private_connection_resource_id = azurerm_key_vault.devops[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "app_configuration" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-appcs-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-app-configuration"
    private_connection_resource_id = azurerm_app_configuration.devops[0].id
    subresource_names              = ["configurationStores"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "servicebus" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-sb-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id
#================================================
  private_service_connection {
    name                           = "psc-servicebus"
    private_connection_resource_id = azurerm_servicebus_namespace.devops[0].id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
# CONTAINER SERVICES
#================================================

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  count               = var.enable_container_registry ? 1 : 0
  name                = "acr${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku                 = var.container_registry_sku
  admin_enabled       = false

  # Security settings
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"

  # Enable geo-replication for Premium SKU
  dynamic "georeplications" {
    for_each = var.container_registry_sku == "Premium" ? var.container_registry_replications : []
    content {
      location = georeplications.value
      tags     = local.common_tags
    }
  }

  tags = local.common_tags
}

# Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "main" {
  count               = var.enable_aks ? 1 : 0
  name                = "aks-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  dns_prefix          = "aks-${local.resource_prefix}"
  kubernetes_version  = var.kubernetes_version

  # Security settings
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  private_dns_zone_id                 = azurerm_private_dns_zone.aks[0].id

  default_node_pool {
    name                = "default"
    node_count          = var.aks_node_count
    vm_size             = var.aks_vm_size
    vnet_subnet_id      = azurerm_subnet.spoke_alpha_workload[0].id
    enable_auto_scaling = true
    min_count          = 1
    max_count          = 5
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = "10.100.0.0/16"
    dns_service_ip    = "10.100.0.10"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
  }

  tags = local.common_tags
}

# Container Instances for serverless containers
resource "azurerm_container_group" "main" {
  count               = var.enable_container_instances ? 1 : 0
  name                = "ci-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.spoke_alpha_workload[0].id]
  os_type             = "Linux"

  container {
    name   = "hello-world"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = local.common_tags
}

# Private DNS Zone for AKS
resource "azurerm_private_dns_zone" "aks" {
  count               = var.enable_aks ? 1 : 0
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Link Private DNS Zone to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "aks_hub" {
  count                 = var.enable_aks ? 1 : 0
  name                  = "pdzvnl-${local.resource_prefix}-aks-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Link Private DNS Zone to Spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "aks_spokes" {
  count                 = var.enable_aks ? var.spoke_count : 0
  name                  = "pdzvnl-${local.resource_prefix}-aks-${local.spoke_names[count.index]}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Private Endpoint for Container Registry
resource "azurerm_private_endpoint" "acr" {
  count               = var.enable_container_registry ? 1 : 0
  name                = "pep-${local.resource_prefix}-acr-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.main[0].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Role assignment for AKS to pull images from ACR
resource "azurerm_role_assignment" "aks_acr" {
  count                = var.enable_aks && var.enable_container_registry ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.main[0].kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.main[0].id
}
