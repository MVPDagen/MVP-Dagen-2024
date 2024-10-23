// Main Input Variabules for Deployment
// TODO: Change these to match your environment
variable "environment" { default = "Dev" }
variable "applicationName" { default = "MVP Dagene 2024" }
variable "customerName" { default = "Elven" }
variable "location" { default = "Norway East" }
variable "deploymentType" { default = "Terraform" }

// Resource Tags for all resources deployed with this Bicep file
// TODO: Change these to match your environment
locals {
  defaultTags = {
    Dataclassification = "Open"
    Criticality = "Normal"
    Costcenter = "Operations"
    Owner = "Jan Vidar Elven"
  }
}

// Resource Group for the deployment
resource "azurerm_resource_group" "rg" {
    name     = "rg-${lower(var.customerName)}-${lower(replace(var.applicationName," ",""))}-${lower(var.deploymentType)}"
    location = var.location
    tags = merge(local.defaultTags, {
        Environment = "${var.environment}"
        Application = "${var.applicationName}-${var.environment}"
        Service = "${var.customerName} ${var.applicationName}"
        Business = "${var.customerName}"
        Deploymenttype = "${var.deploymentType}"       
    })
}

// Using AVM module for User Assigned Managed Identity
module "userAssignedIdentity" {
    source = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
    version = "~> 0.3"
    enable_telemetry = false

    location = azurerm_resource_group.rg.location
    name = "mi-${lower(replace(var.applicationName," ",""))}-${lower(var.deploymentType)}"
    resource_group_name = azurerm_resource_group.rg.name
    
    tags = merge(local.defaultTags, {
        Environment = "${var.environment}"
        Application = "${var.applicationName}-${var.environment}"
        Service = "${var.customerName} ${var.applicationName}"
        Business = "${var.customerName}"
        Deploymenttype = "${var.deploymentType}"       
    })
}

// Get the Service Principal Id of the User Managed Identity resource
data "azuread_service_principal" "miSpn" {
  object_id = module.userAssignedIdentity.principal_id
}

// Get the Resource Id of the Graph resource in the tenant
data "azuread_service_principal" "graphSpn" {
  client_id = "00000003-0000-0000-c000-000000000000"
}

// Define the App Roles to assign to the Managed Identity
variable "appRoles" {
  type = list(string)
  default = [
    "User.Read.All",
    "Device.Read.All"
  ]
}

// Looping through the App Roles and assigning them to the Managed Identity
resource "azuread_app_role_assignment" "assignAppRole" {
  for_each = toset(var.appRoles)
  app_role_id = lookup({ for role in data.azuread_service_principal.graphSpn.app_roles : role.value => role.id }, each.value)
  principal_object_id = data.azuread_service_principal.miSpn.object_id
  resource_object_id = data.azuread_service_principal.graphSpn.object_id
}

