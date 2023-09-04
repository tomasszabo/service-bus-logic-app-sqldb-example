
param location string
param prefix string
param appInsightsConnectionString string
param sqlDbKeyVaultUri string
param serviceBusKeyVaultUri string
param subnetLogicAppId string

param storageAccountName string = '${prefix}blob${uniqueString(resourceGroup().id)}'
param hostingPlanName string = '${prefix}-logicapp-asp-${uniqueString(resourceGroup().id)}'
param logicAppName string = '${prefix}-logicapp-${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'WS1'
    tier: 'Standard'
  }
  properties: {}
}

resource logicApp 'Microsoft.Web/sites@2022-09-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    virtualNetworkSubnetId: subnetLogicAppId
    siteConfig: {
      appSettings: [
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(logicAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
      ]
      connectionStrings: [
        {
          name: 'sql_connectionString'
          type: 'Custom'
          connectionString: '@Microsoft.KeyVault(SecretUri=${sqlDbKeyVaultUri})'
        }
        {
          name: 'serviceBus_connectionString'
          type: 'Custom'
          connectionString: '@Microsoft.KeyVault(SecretUri=${serviceBusKeyVaultUri})'
        }
      ]
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      netFrameworkVersion: '6.0'
      functionsRuntimeScaleMonitoringEnabled: true
      vnetRouteAllEnabled: true
    }
    
    httpsOnly: true
  }
}

output applicationIds array = [logicApp.identity.principalId]
