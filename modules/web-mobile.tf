#================================================
# WEB & MOBILE SERVICES
#================================================

# App Service Plan
resource "azurerm_service_plan" "main" {
  count               = var.enable_app_service ? 1 : 0
  name                = "asp-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = local.common_tags
}

# App Service Environment
resource "azurerm_app_service_environment_v3" "main" {
  count               = var.enable_app_service_environment ? 1 : 0
  name                = "ase-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_workload[0].id

  internal_load_balancing_mode = "Web, Publishing"

  tags = local.common_tags
}

# Linux Web App
resource "azurerm_linux_web_app" "main" {
  count               = var.enable_app_service ? 1 : 0
  name                = "app-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  service_plan_id     = azurerm_service_plan.main[0].id

  # Security settings
  public_network_access_enabled = false
  virtual_network_subnet_id      = azurerm_subnet.spoke_alpha_workload[0].id

  site_config {
    minimum_tls_version = "1.2"
    ftps_state         = "Disabled"

    application_stack {
      node_version = "18-lts"
    }

    # CORS configuration
    cors {
      allowed_origins     = ["https://localhost:3000", "https://*.azurewebsites.net"]
      support_credentials = false
    }

    always_on = true
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = var.enable_app_insights ? azurerm_application_insights.apps[0].instrumentation_key : ""
    "WEBSITE_NODE_DEFAULT_VERSION"        = "18-lts"
    "WEBSITE_RUN_FROM_PACKAGE"           = "1"
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = var.enable_sql_database ? "Server=tcp:${azurerm_mssql_server.main[0].fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main[0].name};Persist Security Info=False;User ID=${azurerm_mssql_server.main[0].administrator_login};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" : ""
  }

  tags = local.common_tags
}

# Function App
resource "azurerm_linux_function_app" "main" {
  count               = var.enable_function_app ? 1 : 0
  name                = "func-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  service_plan_id     = azurerm_service_plan.main[0].id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  # Security settings
  public_network_access_enabled = false
  virtual_network_subnet_id      = azurerm_subnet.spoke_alpha_workload[0].id

  site_config {
    minimum_tls_version = "1.2"
    ftps_state         = "Disabled"

    application_stack {
      node_version = "18"
    }

    cors {
      allowed_origins     = ["https://localhost:3000", "https://*.azurewebsites.net"]
      support_credentials = false
    }

    always_on = true
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"   = "~18"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = var.enable_app_insights ? azurerm_application_insights.apps[0].instrumentation_key : ""
    "AzureWebJobsStorage"            = azurerm_storage_account.main.primary_connection_string
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.main.primary_connection_string
    "WEBSITE_CONTENTSHARE"           = "func-${local.resource_prefix}-content"
  }

  tags = local.common_tags
}

# Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  count                      = var.enable_container_apps ? 1 : 0
  name                       = "cae-${local.resource_prefix}-${format("%03d", 1)}"
  location                   = azurerm_resource_group.spokes[0].location
  resource_group_name        = azurerm_resource_group.spokes[0].name
  log_analytics_workspace_id = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
  infrastructure_subnet_id   = azurerm_subnet.spoke_alpha_workload[0].id

  tags = local.common_tags
}

# Container App
resource "azurerm_container_app" "main" {
  count                        = var.enable_container_apps ? 1 : 0
  name                         = "ca-${local.resource_prefix}-${format("%03d", 1)}"
  container_app_environment_id = azurerm_container_app_environment.main[0].id
  resource_group_name          = azurerm_resource_group.spokes[0].name
  revision_mode                = "Single"

  template {
    container {
      name   = "web-app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = false
    target_port      = 80
  }

  tags = local.common_tags
}

# Azure Spring Apps
resource "azurerm_spring_cloud_service" "main" {
  count               = var.enable_spring_apps ? 1 : 0
  name                = "asa-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku_name            = var.spring_apps_sku

  network {
    cidr_ranges = []
    app_subnet_id             = azurerm_subnet.spoke_alpha_workload[0].id
    service_runtime_subnet_id = azurerm_subnet.spoke_alpha_database[0].id
  }

  tags = local.common_tags
}

# Static Web App
resource "azurerm_static_web_app" "main" {
  count               = var.enable_static_web_app ? 1 : 0
  name                = "stapp-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku_tier            = var.static_web_app_sku
  sku_size            = var.static_web_app_sku

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = var.enable_app_insights ? azurerm_application_insights.apps[0].instrumentation_key : ""
  }

  tags = local.common_tags
}

#================================================
# API MANAGEMENT
#================================================

# API Management
resource "azurerm_api_management" "main" {
  count               = var.enable_api_management ? 1 : 0
  name                = "apim-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  publisher_name      = var.api_management_publisher_name
  publisher_email     = var.api_management_publisher_email
  sku_name            = var.api_management_sku

  # Security settings
  public_network_access_enabled = false
  virtual_network_type          = "Internal"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.spoke_alpha_workload[0].id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# App Configuration
resource "azurerm_app_configuration" "main" {
  count               = var.enable_app_configuration ? 1 : 0
  name                = "appcs-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku                 = var.app_configuration_sku

  # Security settings
    public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Logic Apps (Standard)
resource "azurerm_logic_app_standard" "main" {
  count                      = var.enable_logic_apps ? 1 : 0
  name                       = "logic-${local.resource_prefix}-${format("%03d", 1)}"
  location                   = azurerm_resource_group.spokes[0].location
  resource_group_name        = azurerm_resource_group.spokes[0].name
  app_service_plan_id        = azurerm_service_plan.main[0].id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  # Security settings
  virtual_network_subnet_id = azurerm_subnet.spoke_alpha_workload[0].id

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = var.enable_app_insights ? azurerm_application_insights.apps[0].instrumentation_key : ""
    "FUNCTIONS_WORKER_RUNTIME"       = "node"
  }

  tags = local.common_tags
}

#================================================
# MESSAGING AND NOTIFICATIONS
#================================================

# Communication Services for messaging and calling
resource "azurerm_communication_service" "main" {
  count               = var.enable_communication_services ? 1 : 0
  name                = "comm-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  data_location       = "United States"

  tags = local.common_tags
}

# Email Communication Services
resource "azurerm_email_communication_service" "main" {
  count               = var.enable_email_communication_services ? 1 : 0
  name                = "email-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  data_location       = "United States"

  tags = local.common_tags
}

# Notification Hub Namespace
resource "azurerm_notification_hub_namespace" "main" {
  count               = var.enable_notification_hub ? 1 : 0
  name                = "ntfns-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  namespace_type      = "NotificationHub"
  sku_name            = "Free"

  tags = local.common_tags
}

# Notification Hub
resource "azurerm_notification_hub" "main" {
  count               = var.enable_notification_hub ? 1 : 0
  name                = "ntf-${local.resource_prefix}-main"
  namespace_name      = azurerm_notification_hub_namespace.main[0].name
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
}

# SignalR Service for real-time communication
resource "azurerm_signalr_service" "main" {
  count               = var.enable_signalr ? 1 : 0
  name                = "signalr-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name

  sku {
    name     = var.signalr_sku_name
    capacity = var.signalr_capacity
  }

  # Security settings
  public_network_access_enabled = false

  cors {
    allowed_origins = ["https://localhost:3000", "https://*.azurewebsites.net"]
  }

  connectivity_logs_enabled = true
  messaging_logs_enabled    = true
  service_mode             = "Default"

  tags = local.common_tags
}

# Web PubSub Service
resource "azurerm_web_pubsub" "main" {
  count               = var.enable_web_pubsub ? 1 : 0
  name                = "wps-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku                 = var.web_pubsub_sku
  capacity            = var.web_pubsub_capacity

  # Security settings
  public_network_access_enabled = false

  tags = local.common_tags
}

# Fluid Relay for collaborative experiences
resource "azurerm_fluid_relay_server" "main" {
  count               = var.enable_fluid_relay ? 1 : 0
  name                = "frs-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

#================================================
# MEDIA SERVICES AND SEARCH
#================================================

# Search Service (AI Search)
resource "azurerm_search_service" "main" {
  count                         = var.enable_search_service ? 1 : 0
  name                          = "srch-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name           = azurerm_resource_group.spokes[0].name
  location                      = azurerm_resource_group.spokes[0].location
  sku                          = var.search_service_sku
  replica_count                = var.search_service_replica_count
  partition_count              = var.search_service_partition_count
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Media Services Account
# Storage Account for Media Services
resource "azurerm_storage_account" "media" {
  count                    = var.enable_media_services ? 1 : 0
  name                     = "st${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}media${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.spokes[0].name
  location                 = azurerm_resource_group.spokes[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security settings
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  tags = local.common_tags
}

#================================================
# CDN AND FRONT DOOR
#================================================

# CDN Profile for web content delivery
resource "azurerm_cdn_profile" "web" {
  count               = var.enable_web_cdn ? 1 : 0
  name                = "cdn-${local.resource_prefix}-web-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku                 = "Standard_Microsoft"

  tags = local.common_tags
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "web" {
  count                         = var.enable_web_cdn ? 1 : 0
  name                          = "cdn-${local.resource_prefix}-web-${format("%03d", 1)}"
  profile_name                  = azurerm_cdn_profile.web[0].name
  location                      = azurerm_resource_group.spokes[0].location
  resource_group_name           = azurerm_resource_group.spokes[0].name
  is_http_allowed               = false
  is_https_allowed              = true
  querystring_caching_behaviour = "IgnoreQueryString"
  is_compression_enabled        = true

  content_types_to_compress = [
    "application/javascript",
    "application/json",
    "application/xml",
    "text/css",
    "text/html",
    "text/javascript",
    "text/plain"
  ]

  origin {
    name      = "web-app"
    host_name = var.enable_app_service ? azurerm_linux_web_app.main[0].default_hostname : var.enable_static_web_app ? azurerm_static_web_app.main[0].default_host_name : "example.com"
  }

  tags = local.common_tags
}

# Front Door for global load balancing
resource "azurerm_cdn_frontdoor_profile" "main" {
  count               = var.enable_front_door ? 1 : 0
  name                = "fd-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku_name            = var.front_door_sku

  tags = local.common_tags
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  count                    = var.enable_front_door ? 1 : 0
  name                     = "fd-endpoint-${local.resource_prefix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id

  tags = local.common_tags
}

# Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "main" {
  count                    = var.enable_front_door ? 1 : 0
  name                     = "fd-origin-group-${local.resource_prefix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# Front Door Origin
resource "azurerm_cdn_frontdoor_origin" "main" {
  count                         = var.enable_front_door && var.enable_app_service ? 1 : 0
  name                          = "fd-origin-${local.resource_prefix}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main[0].id

  enabled                        = true
  host_name                      = azurerm_linux_web_app.main[0].default_hostname
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_linux_web_app.main[0].default_hostname
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

#================================================
# APPLICATION INSIGHTS AND MONITORING
#================================================

# Application Insights for Web & Mobile Apps
resource "azurerm_application_insights" "apps" {
  count               = var.enable_app_insights ? 1 : 0
  name                = "appi-${local.resource_prefix}-apps-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  application_type    = "web"
  workspace_id        = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null

  tags = local.common_tags
}

# Mobile App Backend (App Service with mobile optimizations)
resource "azurerm_linux_web_app" "mobile_backend" {
  count               = var.enable_mobile_backend ? 1 : 0
  name                = "mobile-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  service_plan_id     = azurerm_service_plan.main[0].id

  # Security settings
  public_network_access_enabled = false
  virtual_network_subnet_id      = azurerm_subnet.spoke_alpha_workload[0].id

  site_config {
    minimum_tls_version = "1.2"
    ftps_state         = "Disabled"

    cors {
      allowed_origins = ["*"]
    }

    application_stack {
      dotnet_version = "8.0"
    }

    always_on = true
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = var.enable_app_insights ? azurerm_application_insights.apps[0].instrumentation_key : ""
    "AZURE_MOBILE_BACKEND"           = "true"
    "MOBILE_API_VERSION"             = "v1"
    "CORS_ALLOWED_ORIGINS"           = "*"
  }

  tags = local.common_tags
}

#================================================
# PRIVATE ENDPOINTS
#================================================

# Private Endpoints for Web & Mobile Services
resource "azurerm_private_endpoint" "web_app" {
  count               = var.enable_app_service ? 1 : 0
  name                = "pep-${local.resource_prefix}-app-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-web-app"
    private_connection_resource_id = azurerm_linux_web_app.main[0].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "function_app" {
  count               = var.enable_function_app ? 1 : 0
  name                = "pep-${local.resource_prefix}-func-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-function-app"
    private_connection_resource_id = azurerm_linux_function_app.main[0].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "api_management" {
  count               = var.enable_api_management ? 1 : 0
  name                = "pep-${local.resource_prefix}-apim-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-api-management"
    private_connection_resource_id = azurerm_api_management.main[0].id
    subresource_names              = ["Gateway"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "signalr" {
  count               = var.enable_signalr ? 1 : 0
  name                = "pep-${local.resource_prefix}-signalr-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-signalr"
    private_connection_resource_id = azurerm_signalr_service.main[0].id
    subresource_names              = ["signalr"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "web_pubsub" {
  count               = var.enable_web_pubsub ? 1 : 0
  name                = "pep-${local.resource_prefix}-wps-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-web-pubsub"
    private_connection_resource_id = azurerm_web_pubsub.main[0].id
    subresource_names              = ["webpubsub"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "mobile_backend" {
  count               = var.enable_mobile_backend ? 1 : 0
  name                = "pep-${local.resource_prefix}-mobile-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-mobile-backend"
    private_connection_resource_id = azurerm_linux_web_app.mobile_backend[0].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "search_service" {
  count               = var.enable_search_service ? 1 : 0
  name                = "pep-${local.resource_prefix}-srch-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-search-service"
    private_connection_resource_id = azurerm_search_service.main[0].id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "app_configuration" {
  count               = var.enable_app_configuration ? 1 : 0
  name                = "pep-${local.resource_prefix}-appcs-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-app-configuration"
    private_connection_resource_id = azurerm_app_configuration.main[0].id
    subresource_names              = ["configurationStores"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "media_services" {
  count               = var.enable_media_services ? 1 : 0
  name                = "pep-${local.resource_prefix}-ams-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-media-services"
    private_connection_resource_id = azurerm_media_services_account.main[0].id
    subresource_names              = ["streamingEndpoint"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

