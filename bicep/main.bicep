@description('Azure location where resources should be deployed (e.g., westeurope)')
param location string = 'westeurope'

param sqlAdmin string = 'sqladmin'
@secure()
param sqlPassword string

param prefix string = 'lat'

module sharedModule './shared.bicep' = {
  name: 'sharedModule'
  params: {
    location: location
    prefix: prefix
  }
}

module keyVaultModule './keyVault.bicep' = {
  name: 'keyVaultModule'
  params: {
    location: location
    prefix: prefix
  }
}

module networkModule './network.bicep' = {
  name: 'networkModule'
  dependsOn: [
    sharedModule
  ]
  params: {
    location: location
    prefix: prefix
  }
}

module databaseModule './database.bicep' = {
  name: 'databaseModule'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    administratorLogin: sqlAdmin
    administratorLoginPassword: sqlPassword
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
  }
}

module serviceBusModule './serviceBus.bicep' = {
  name: 'serviceBusModule'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
  }
}

module storageModule './storage.bicep' = {
  name: 'storageModule'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
  }
}

module privateEndpointsModule './private-endpoints.bicep' = {
  name: 'privateEndpointsModule'
  dependsOn: [
    keyVaultModule
    networkModule
    databaseModule
    serviceBusModule
  ]
  params: {
    location: location
    prefix: prefix
    vnetName: networkModule.outputs.vnetName
    sqlName: databaseModule.outputs.sqlName
    subnetName: networkModule.outputs.privateEndpointsSubnetName
    serviceBusNamespaceName: serviceBusModule.outputs.serviceBusNamespaceName
    storageAccountName: storageModule.outputs.storageAccountName
    keyVaultName: keyVaultModule.outputs.keyVaultName
  }
}

module logicAppModule './logicapp.bicep' = {
  name: 'logicAppModule'
  dependsOn: [
    sharedModule
    privateEndpointsModule
  ]
  params: {
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
    appInsightsConnectionString: sharedModule.outputs.appInsightsConnectionString
    sqlDbKeyVaultUri: databaseModule.outputs.connectionStringKeyVaultUri
    serviceBusKeyVaultUri: serviceBusModule.outputs.connectionStringKeyVaultUri
    subnetLogicAppId: networkModule.outputs.subnetLogicAppId
    storageAccountName: storageModule.outputs.storageAccountName
    storageKeyVaultSecretUri: storageModule.outputs.connectionStringKeyVaultUri
  }
}
