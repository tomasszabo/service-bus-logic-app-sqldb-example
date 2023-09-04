
param location string
param prefix string

param vnetName string = '${prefix}-vnet-${uniqueString(resourceGroup().id)}'
param vnetAddressPrefix string = '10.0.0.0/16'
param subnetLogicAppName string = 'logic-apps'
param subnetLogicAppPrefix string = '10.0.1.0/26'
param subnetPrivateEndpointsName string = 'private-endpoints'
param subnetPrivateEndpointsPrefix string = '10.0.2.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetLogicAppName
        properties: {
          addressPrefix: subnetLogicAppPrefix
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: subnetPrivateEndpointsName
        properties: {
          addressPrefix: subnetPrivateEndpointsPrefix
        }
      }
    ]
  }
}

output vnetName string = vnetName
output privateEndpointsSubnetName string = subnetPrivateEndpointsName
output subnetLogicAppId string = vnet.properties.subnets[0].id
