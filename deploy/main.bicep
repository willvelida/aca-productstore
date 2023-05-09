@description('The suffix applied to our application.')
param applicationName string = uniqueString(resourceGroup().id)

@description('The location to deploy our resources to. Default is location of resource group')
param location string = resourceGroup().location

@description('Specifies the name of our container registry')
param containerRegistryName string = '${applicationName}acr'

@description('Specifies the name of the Log Analytics workspace resource')
param logAnalyticsWorkspaceName string = '${applicationName}law'

@description('Specifies the name of the application insights workspace resource')
param appInsightsName string = '${applicationName}ai'

@description('Specifies the name of the Container App Environment')
param containerAppEnvironmentName string = '${applicationName}env'

var tags = {
  Environment: 'Production'
  ApplicationName: 'aca-productstore'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: containerRegistryName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource env 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: containerAppEnvironmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}
