
// Main Bicep deployment file for Azure and Graph resources
// Topic: MVP Dagene 2024
// Created by: Jan Vidar Elven
// Last Updated: 23.10.2024

targetScope = 'subscription'

// Main Parameters for Deployment
// TODO: Change these to match your environment
param environment string = 'Dev'
param applicationName string = 'MVP Dagene 2024'
param customerName string = 'Elven'
param location string = 'norwayeast'
param deploymentType string = 'Bicep'
param resourceGroupName string = 'rg-${toLower(customerName)}-${toLower(replace(applicationName,' ',''))}-${toLower(deploymentType)}'

// Resource Tags for all resources deployed with this Bicep file
// TODO: Change these to match your environment
var defaultTags = {
  Environment: environment
  Application: '${applicationName}-${environment}'
  Dataclassification: 'Open'
  Costcenter: 'Operations'
  Criticality: 'Normal'
  Service: '${customerName} ${applicationName}'
  Deploymenttype: deploymentType
  Owner: 'Jan Vidar Elven'
  Business: customerName
}

// Resource Group for the deployment
resource rg 'Microsoft.Resources/resourceGroups@2024-08-01' = {
  name: resourceGroupName
  location: location
  tags: defaultTags
}

// Using AVM module for User Assigned Managed Identity
module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'userAssignedIdentityDeployment'
  scope: resourceGroup(rg.name)  
  params: {
    // Required parameters
    name: 'mi-${toLower(replace(applicationName,' ',''))}-${toLower(deploymentType)}'
  }
}

// Initialize the Graph provider
provider microsoftGraph

// Get the Principal Id of the User Managed Identity resource
resource miSpn 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: userAssignedIdentity.outputs.clientId

}

// Get the Resource Id of the Graph resource in the tenant
resource graphSpn 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: '00000003-0000-0000-c000-000000000000'
}

// Define the App Roles to assign to the Managed Identity
param appRoles array = [
  'User.Read.All'
  'Device.Read.All'
]

// Looping through the App Roles and assigning them to the Managed Identity
resource assignAppRole 'Microsoft.Graph/appRoleAssignedTo@v1.0' = [for appRole in appRoles: {
  appRoleId: (filter(graphSpn.appRoles, role => role.value == appRole)[0]).id
  principalId: miSpn.id
  resourceId: graphSpn.id
}]

// Using AVM Module for Logic App Workflow
module logicApp 'br/public:avm/res/logic/workflow:0.4.0' = {
  name: 'logicAppDeployment'
  scope: resourceGroup(rg.name)
  params: {
    // Required parameters
    name: 'logicapp-${toLower(replace(applicationName,' ',''))}-${toLower(deploymentType)}'
    location: location
    managedIdentities: {
      userAssignedResourceIds: [
        userAssignedIdentity.outputs.resourceId
      ]
    }
    tags: defaultTags
    workflowTriggers: {
      request: {
        type: 'Request'
        kind: 'Http'
        inputs: {
          schema: {}
        }
      }
    }
    workflowActions: {
      HTTP: {
        type: 'Http'
        runAfter: {}
        inputs: {
          uri: 'https://graph.microsoft.com/v1.0/users/$count?$filter=userType%20ne%20\'guest\''
          method: 'GET'
          headers: {
            consistencyLevel: 'eventual'
          }
          authentication: {
            type: 'ManagedServiceIdentity'
            identity: userAssignedIdentity.outputs.resourceId
            audience: 'https://graph.microsoft.com'
          }
        }
      }
      Response: {
        runAfter: {
          HTTP: [
            'Succeeded'
          ]
        }
        type: 'Response'
        inputs: {
          statusCode: 200
          body: '@body(\'HTTP\')'
        }
      }        
    }    
  }
}
