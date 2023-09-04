
param keyVaultName string
param location string
param prefix string
param administratorLogin string
@secure()
param administratorLoginPassword string

param serverName string = '${prefix}-sql-server-${uniqueString(resourceGroup().id)}'
param databaseName string = '${prefix}-sql-db-${uniqueString(resourceGroup().id)}'

resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    publicNetworkAccess: 'Disabled'
  } 
}

resource database 'Microsoft.Sql/servers/databases@2022-11-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

module connectionStringSecret 'keyVaultSecret.bicep' = {
  name: 'sqlKeyVaultSecretPrimaryConnectionString'
  params: {
    keyVaultName: keyVaultName
    secretName: '${databaseName}-PrimaryConnectionString'
    secretValue: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};User Id=${administratorLogin}@${serverName};Password=${administratorLoginPassword};'
  }
}

output connectionStringKeyVaultUri string = connectionStringSecret.outputs.keyVaultSecretUri
output sqlName string = sqlServer.name
