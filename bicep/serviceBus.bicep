
param location string
param prefix string
param keyVaultName string

param suffix string = uniqueString(resourceGroup().id)
param serviceBusNamespaceName string = '${prefix}-service-bus-${suffix}'
param serviceBusQueueName string = 'testqueue'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: serviceBusQueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

module connectionStringSecret 'keyVaultSecret.bicep' = {
  name: 'serviceBusKeyVaultSecretPrimaryConnectionString'
  params: {
    keyVaultName: keyVaultName
    secretName: '${serviceBusNamespaceName}-PrimaryConnectionString'
    secretValue: listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString
  }
}

output connectionStringKeyVaultUri string = connectionStringSecret.outputs.keyVaultSecretUri
output serviceBusNamespaceName string = serviceBusNamespace.name
