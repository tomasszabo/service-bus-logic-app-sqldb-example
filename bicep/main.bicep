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

module privateEndpointsModule './private-endpoints.bicep' = {
  name: 'privateEndpointsModule'
  dependsOn: [
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
  }
}

module logicAppModule './logicapp.bicep' = {
  name: 'computeModule'
  dependsOn: [
    sharedModule
  ]
  params: {
    location: location
    prefix: prefix
    appInsightsConnectionString: sharedModule.outputs.appInsightsConnectionString
    sqlDbKeyVaultUri: databaseModule.outputs.connectionStringKeyVaultUri
    serviceBusKeyVaultUri: serviceBusModule.outputs.connectionStringKeyVaultUri
    subnetLogicAppId: networkModule.outputs.subnetLogicAppId
  }
}

module keyVaultAccessPolicyModule './keyVaultAccessPolicy.bicep' = { 
  name: 'keyVaultAccessPolicyModule'
  dependsOn: [
    logicAppModule
  ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    applicationIds: logicAppModule.outputs.applicationIds
  }
}
