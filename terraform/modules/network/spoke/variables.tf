# Spoke Network Module - Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "spoke_vnet_name" {
  description = "Name of the spoke virtual network"
  type        = string
}

variable "spoke_address_space" {
  description = "Address space for spoke VNet"
  type        = list(string)
}

variable "hub_vnet_id" {
  description = "ID of the hub virtual network"
  type        = string
}

variable "hub_resource_group" {
  description = "Name of the hub resource group"
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
