
param location string
param prefix string
param keyVaultName string
param appInsightsConnectionString string
param sqlDbKeyVaultUri string
param serviceBusKeyVaultUri string
param subnetLogicAppId string
param storageKeyVaultSecretUri string
param storageAccountName string

param hostingPlanName string = '${prefix}-logicapp-asp-${uniqueString(resourceGroup().id)}'
param logicAppName string = '${prefix}-logicapp-${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' existing = {
  name: 'default'
  parent: storageAccount
}

// create file share for logic app (created automatically when deploying manually in Azure Portal, in IaC need to create it manually)
resource logicAppFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: logicAppName
  parent: fileShares
  properties: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
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
      functionsRuntimeScaleMonitoringEnabled: false
      vnetRouteAllEnabled: true
    }
    
    httpsOnly: true
  }
}

// need to grant access to KeyVault for Logic App first before we can set the app settings
module keyVaultAccessPolicyModule './keyVaultAccessPolicy.bicep' = { 
  name: 'keyVaultAccessPolicyModule'
  params: {
    keyVaultName: keyVaultName
    applicationIds: [logicApp.identity.principalId]
  }
}

resource logicAppSettings 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: logicApp
  name: 'appsettings'
  dependsOn: [
    keyVaultAccessPolicyModule
  ]
  properties: {
    APP_KIND: 'workflowApp'
    AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
    AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${storageKeyVaultSecretUri})'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=${storageKeyVaultSecretUri})'
    WEBSITE_CONTENTSHARE: toLower(logicAppName)
    WEBSITE_CONTENTOVERVNET: '1'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
    FUNCTIONS_WORKER_RUNTIME: 'node'
    WEBSITE_NODE_DEFAULT_VERSION: '~18'
  }
}
