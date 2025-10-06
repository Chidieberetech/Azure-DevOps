#================================================
# INTERNET OF THINGS (IoT) SERVICES
#================================================

# IoT Hub
resource "azurerm_iothub" "main" {
  count               = var.enable_iot_hub ? 1 : 0
  name                = "iot-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location

  sku {
    name     = var.iot_hub_sku_name
    capacity = var.iot_hub_capacity
  }

  # Security settings
  public_network_access_enabled = false

  tags = local.common_tags
}

# IoT Hub DPS (Device Provisioning Service)
resource "azurerm_iothub_dps" "main" {
  count               = var.enable_iot_dps ? 1 : 0
  name                = "dps-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location

  sku {
    name     = "S1"
    capacity = "1"
  }

  linked_hub {
    connection_string       = azurerm_iothub.main[0].shared_access_policy[0].primary_connection_string
    location                = azurerm_resource_group.spokes[0].location
    allocation_weight       = 1
    apply_allocation_policy = true
  }

  tags = local.common_tags
}

# Digital Twins Instance
resource "azurerm_digital_twins_instance" "main" {
  count               = var.enable_digital_twins ? 1 : 0
  name                = "dt-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location

  tags = local.common_tags
}

# IoT Central Application
resource "azurerm_iotcentral_application" "main" {
  count               = var.enable_iot_central ? 1 : 0
  name                = "iotc-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sub_domain          = "iotc-${local.resource_prefix}-${format("%03d", 1)}"
  display_name        = "IoT Central - ${local.resource_prefix}"
  sku                 = "ST1"
  template            = "iotc-pnp-preview@1.0.0"

  tags = local.common_tags
}

# Maps Account for location services
resource "azurerm_maps_account" "main" {
  count               = var.enable_maps ? 1 : 0
  name                = "map-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku_name            = var.maps_sku_name

  tags = local.common_tags
}

# Private Endpoints for IoT Services
resource "azurerm_private_endpoint" "iot_hub" {
  count               = var.enable_iot_hub ? 1 : 0
  name                = "pep-${local.resource_prefix}-iot-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-iot-hub"
    private_connection_resource_id = azurerm_iothub.main[0].id
    subresource_names              = ["iotHub"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "iot_dps" {
  count               = var.enable_iot_dps ? 1 : 0
  name                = "pep-${local.resource_prefix}-dps-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-iot-dps"
    private_connection_resource_id = azurerm_iothub_dps.main[0].id
    subresource_names              = ["iotDps"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "digital_twins" {
  count               = var.enable_digital_twins ? 1 : 0
  name                = "pep-${local.resource_prefix}-dt-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-digital-twins"
    private_connection_resource_id = azurerm_digital_twins_instance.main[0].id
    subresource_names              = ["API"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
