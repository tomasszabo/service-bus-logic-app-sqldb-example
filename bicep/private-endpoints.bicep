param location string
param prefix string
param vnetName string
param sqlName string
param subnetName string
param serviceBusNamespaceName string

param sqlPrivateEndpointName string = '${prefix}-sqlPrivateEndpoint'
param sqlPrivateLinkName string = '${prefix}-sqlPrivateLink'
param sqlPrivateDnsZoneName string = 'privatelink${environment().suffixes.sqlServerHostname}'
param sqlPrivateDnsGroupName string = '${sqlPrivateEndpointName}/customdnsgroupname'
param serviceBusPrivateEndpointName string = '${prefix}-serviceBusPrivateEndpoint'
param serviceBusPrivateLinkName string = '${prefix}-serviceBusPrivateLink'
param serviceBusPrivateDnsZoneName string = 'privatelink.servicebus.windows.net'
param serviceBusPrivateDnsGroupName string = '${serviceBusPrivateEndpointName}/customdnsgroupname'

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' existing = {
  name: sqlName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  parent: vnet
  name: subnetName
}

resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: sqlPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: sqlPrivateLinkName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource serviceBusPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-02-01' = {
  name: serviceBusPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: serviceBusPrivateLinkName
        properties: {
          privateLinkServiceId: serviceBusNamespace.id
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }
}

resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: sqlPrivateDnsZoneName
  location: 'global'
  properties: {}
}

resource serviceBusPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: serviceBusPrivateDnsZoneName
  location: 'global'
  properties: {}
}

resource sqlPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: sqlPrivateDnsZone
  name: '${sqlPrivateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource serviceBusPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: serviceBusPrivateDnsZone
  name: '${serviceBusPrivateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource sqlPrivateDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: sqlPrivateDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sqlConfig'
        properties: {
          privateDnsZoneId: sqlPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    sqlPrivateEndpoint
  ]
}

resource serviceBusPrivateDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: serviceBusPrivateDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'serviceBusConfig'
        properties: {
          privateDnsZoneId: serviceBusPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    serviceBusPrivateEndpoint
  ]
}

