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

@description('Specifies the name of the Azure Load Test resource')
param loadTestName string = 'wvacaloadtest'

@maxLength(12)
@description('The name of the Action Group that will receive alerts for this application')
param actionGroupName string = 'PSOC team'

@description('The Action Group Email')
param actionGroupEmail string = 'willvelida@microsoft.com'

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

resource loadTest 'Microsoft.LoadTestService/loadTests@2022-12-01' = {
  name: loadTestName
  location: location
  properties: {
    
  }
}

resource supportTeamActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    enabled: true
    groupShortName: actionGroupName
    emailReceivers: [
      {
        name: actionGroupName
        emailAddress: actionGroupEmail
        useCommonAlertSchema: true
      }
    ]
  }
}
