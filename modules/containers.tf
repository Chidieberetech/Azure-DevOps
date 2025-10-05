#================================================
# CONTAINER RESOURCES
#================================================

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  count               = var.enable_containers && var.enable_container_registry ? 1 : 0
  name                = "acr${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  sku                 = var.container_registry_sku
  admin_enabled       = var.container_registry_admin_enabled

  # Geo-replication for higher SKUs
  dynamic "georeplications" {
    for_each = var.container_registry_sku == "Premium" && var.enable_container_registry_georeplication ? [1] : []
    content {
      location                = var.location_secondary
      zone_redundancy_enabled = false
      tags                    = local.common_tags
    }
  }

  # Network rule set for Premium SKU
  dynamic "network_rule_set" {
    for_each = var.container_registry_sku == "Premium" && var.enable_private_endpoints ? [1] : []
    content {
      default_action = "Deny"

      ip_rule {
        action   = "Allow"
        ip_range = "10.0.0.0/8"  # Allow internal network traffic
      }
    }
  }

  tags = local.common_tags
}

# Azure Kubernetes Service (AKS) Cluster
resource "azurerm_kubernetes_cluster" "main" {
  count               = var.enable_containers && var.enable_aks ? 1 : 0
  name                = "aks-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  dns_prefix          = "aks-trl-${var.environment}"
  kubernetes_version  = var.aks_kubernetes_version

  # Default node pool
  default_node_pool {
    name                = "default"
    node_count          = var.aks_node_count
    vm_size             = var.aks_vm_size
    type                = "VirtualMachineScaleSets"
    availability_zones  = var.aks_availability_zones
    enable_auto_scaling = var.aks_enable_auto_scaling
    min_count           = var.aks_enable_auto_scaling ? var.aks_min_count : null
    max_count           = var.aks_enable_auto_scaling ? var.aks_max_count : null
    max_pods            = var.aks_max_pods
    os_disk_size_gb     = var.aks_os_disk_size
    vnet_subnet_id      = var.enable_aks_vnet_integration ? azurerm_subnet.hub_aks[0].id : null

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # Identity
  identity {
    type = "SystemAssigned"
  }

  # Network profile for Azure CNI
  dynamic "network_profile" {
    for_each = var.enable_aks_vnet_integration ? [1] : []
    content {
      network_plugin    = "azure"
      network_policy    = "azure"
      dns_service_ip    = var.aks_dns_service_ip
      service_cidr      = var.aks_service_cidr
      load_balancer_sku = "standard"
    }
  }

  # Azure Active Directory integration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_aks_rbac ? [1] : []
    content {
      managed                = true
      admin_group_object_ids = var.aks_admin_group_object_ids
      azure_rbac_enabled     = true
    }
  }

  # Add-ons
  dynamic "oms_agent" {
    for_each = var.enable_analytics && var.enable_aks_monitoring ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id
    }
  }

  dynamic "azure_policy" {
    for_each = var.enable_aks_azure_policy ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "http_application_routing" {
    for_each = var.enable_aks_http_application_routing ? [1] : []
    content {
      enabled = true
    }
  }

  tags = local.common_tags
}

# Additional AKS Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count                 = var.enable_containers && var.enable_aks && var.enable_aks_spot_node_pool ? 1 : 0
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main[0].id
  vm_size               = var.aks_spot_vm_size
  node_count            = var.aks_spot_node_count
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = var.aks_spot_max_price

  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]

  tags = local.common_tags
}

# Container Instances for serverless containers
resource "azurerm_container_group" "main" {
  count               = var.enable_containers && var.enable_container_instances ? 1 : 0
  name                = "ci-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  ip_address_type     = var.container_instances_ip_address_type
  dns_name_label      = var.container_instances_dns_name_label
  os_type             = "Linux"
  subnet_ids          = var.enable_container_instances_vnet_integration ? [azurerm_subnet.hub_containers[0].id] : null

  container {
    name   = "nginx"
    image  = "nginx:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "ENVIRONMENT" = var.environment
    }
  }

  tags = local.common_tags
}

# Azure Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  count                      = var.enable_containers && var.enable_container_apps ? 1 : 0
  name                       = "cae-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location                   = azurerm_resource_group.management.location
  resource_group_name        = azurerm_resource_group.management.name
  log_analytics_workspace_id = var.enable_analytics ? azurerm_log_analytics_workspace.main[0].id : null

  tags = local.common_tags
}

# Sample Container App
resource "azurerm_container_app" "main" {
  count                        = var.enable_containers && var.enable_container_apps ? 1 : 0
  name                         = "ca-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  container_app_environment_id = azurerm_container_app_environment.main[0].id
  resource_group_name          = azurerm_resource_group.management.name
  revision_mode                = "Single"

  template {
    container {
      name   = "webapp"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = local.common_tags
}

# Dedicated subnets for container services
resource "azurerm_subnet" "hub_aks" {
  count                = var.enable_containers && var.enable_aks && var.enable_aks_vnet_integration ? 1 : 0
  name                 = "snet-aks-${local.env_abbr[var.environment]}-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.aks_subnet_address_prefix]
}

resource "azurerm_subnet" "hub_containers" {
  count                = var.enable_containers && var.enable_container_instances && var.enable_container_instances_vnet_integration ? 1 : 0
  name                 = "snet-containers-${local.env_abbr[var.environment]}-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.containers_subnet_address_prefix]

  delegation {
    name = "Microsoft.ContainerInstance/containerGroups"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Private Endpoints for Container Services
resource "azurerm_private_endpoint" "container_registry" {
  count               = var.enable_containers && var.enable_container_registry && var.container_registry_sku == "Premium" && var.enable_private_endpoints ? 1 : 0
  name                = "pe-acr-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-acr-trl-${local.env_abbr[var.environment]}"
    private_connection_resource_id = azurerm_container_registry.main[0].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Role assignments for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.enable_containers && var.enable_aks && var.enable_container_registry ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.main[0].kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.main[0].id
}
