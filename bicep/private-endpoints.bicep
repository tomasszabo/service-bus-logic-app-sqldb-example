param location string
param prefix string
param vnetName string
param sqlName string
param subnetName string
param serviceBusNamespaceName string
param storageAccountName string
param keyVaultName string

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  parent: vnet
  name: subnetName
}

resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' existing = {
  name: sqlName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

var endpoints = [
  {
    name: 'sql'
    dnsZoneName: 'privatelink${environment().suffixes.sqlServerHostname}'
    groupIds: ['sqlServer']
    serviceId: sqlServer.id
  }
  {
    name: 'serviceBus'
    dnsZoneName: 'privatelink.servicebus.windows.net'
    groupIds: ['namespace']
    serviceId: serviceBusNamespace.id
  }
  {
    name: 'storage-blob'
    dnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
    groupIds: ['blob']
    serviceId: storageAccount.id
  }
  {
    name: 'storage-file'
    dnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
    groupIds: ['file']
    serviceId: storageAccount.id
  }
  {
    name: 'storage-queue'
    dnsZoneName: 'privatelink.queue.${environment().suffixes.storage}'
    groupIds: ['queue']
    serviceId: storageAccount.id
  }
  {
    name: 'storage-table'
    dnsZoneName: 'privatelink.table.${environment().suffixes.storage}'
    groupIds: ['table']
    serviceId: storageAccount.id
  }
  {
    name: 'keyVault'
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    groupIds: ['vault']
    serviceId: keyVault.id
  }
]

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = [for (endpoint, i) in endpoints: {
  name: '${prefix}-${endpoint.name}PrivateEndpoint'
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${prefix}-${endpoint.name}PrivateLink'
        properties: {
          privateLinkServiceId: endpoint.serviceId
          groupIds: endpoint.groupIds
        }
      }
    ]
  }
}]

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for (endpoint, i) in endpoints: {
  name: endpoint.dnsZoneName
  location: 'global'
  properties: {}
}]

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (endpoint, i) in endpoints: {
  parent: privateDnsZone[i]
  name: '${endpoint.dnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}]

resource privateDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = [for (endpoint, i) in endpoints: {
  parent: privateEndpoint[i]
  name: 'customdnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateDnsZone[i].id
        }
      }
    ]
  }
}]



