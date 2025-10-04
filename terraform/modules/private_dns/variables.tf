# Private DNS Module - Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "hub_vnet_id" {
  description = "ID of the hub virtual network"
  type        = string
}

variable "spoke_vnet_ids" {
  description = "List of spoke virtual network IDs"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
