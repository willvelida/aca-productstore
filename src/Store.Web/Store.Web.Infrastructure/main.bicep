@description('The location to deploy our resources to. Default is location of resource group')
param location string = resourceGroup().location

@description('The name of our application.')
param applicationName string = uniqueString(resourceGroup().id)

@description('Specifies the name of the application insights workspace resource')
param appInsightsName string = '${applicationName}ai'

@description('Specifies the name of the Container App Environment')
param containerAppEnvironmentName string = '${applicationName}env'

@description('Specifies the name of our container registry')
param containerRegistryName string = '${applicationName}acr'

@description('The image used by this Container App')
param containerImageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var appName = 'store-web'
var inventoryAppName = 'store-inventory-api'
var productAppName = 'store-product-api'
var tags = {
  Environment: 'Production'
  ApplicationName: 'aca-productstore'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource env 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: containerAppEnvironmentName
}

resource productsApp 'Microsoft.App/containerApps@2022-11-01-preview' existing = {
  name: productAppName
}

resource inventoryApp 'Microsoft.App/containerApps@2022-11-01-preview' existing = {
  name: inventoryAppName
}

resource productApi 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: appName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: [
        {
          name: 'container-registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: '${containerRegistry.name}.azurecr.io'
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'container-registry-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
        transport: 'http'
        allowInsecure: true
      }
    }
    template: {
      containers: [
        {
          image: containerImageName
          name: appName
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsights.properties.InstrumentationKey
            }
            {
              name: 'APPINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
            {
              name: 'ProductsApi'
              value: 'http://${productsApp.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'InventoryApi'
              value: 'http://${inventoryApp.properties.configuration.ingress.fqdn}'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-scale-rule'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}


