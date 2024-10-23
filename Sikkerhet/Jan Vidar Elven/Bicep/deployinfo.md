# Azure Deployment for Bicep

To deploy use this deployment guide instructions:

## Azure Login

You need to be logged into the target Azure environment and subscription.

```azurecli
az login --scope https://management.azure.com//.default --use-device-code --tenant <yourtenant>.onmicrosoft.com

az account set --subscription "<your-azure-subscription-id-or-name>"
```

## Azure Subscription Deployment

```azurecli
az deployment sub create --name 'deploy-elven-mvpdagene' --location norwayeast --template-file main.bicep
```

## Azure Deployment Stack (NOT SUPPORTED WITH BICEP GRAPH EXTENSIONS)

If and when Graph and Bicep Extensions will support Deployment Stacks, we will be using Azure and Deployment Stack using Bicep.

```azurecli
az stack sub create --location NorwayEast --name "stack-elven-mvpdagene" --template-file .\main.bicep --deny-settings-mode none --action-on-unmanage deleteResources

az stack sub create --location NorwayEast --name "stack-elven-mvpdagene" --template-file .\main.bicep --parameters SOMEOPTIONALPARAMETER=false --deny-settings-mode none --action-on-unmanage deleteResources
```
