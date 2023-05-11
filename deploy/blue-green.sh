# Login into Azure
az login

# Set name of Resource Group
RG_NAME='<resource-group-name>'

# get ACR name
ACR_NAME=$(az acr list --resource-group $RG_NAME --query "[0].name" -o tsv)
ACR_LOGIN_SERVER=$(az acr list --resource-group $RG_NAME --query "[0].loginServer" -o tsv) 

# login to ACR
az acr login -n $ACR_NAME

# Build and push to ACR
docker build - -t $ACR_LOGIN_SERVER/productapi:latest
docker push $ACR_LOGIN_SERVER/productapi:latest

# Get current revision
az extension add --name containerapp --upgrade
CURRENT_REVISION=$(az containerapp revision list -g $RG_NAME -n store-product-api --query 'reverse(sort_by([].{Revision:name,Replicas:properties.replicas,Active:properties.active,Created:properties.createdTime,FQDN:properties.fqdn}[?Active!=`false`], &Created))| [0].Revision' -o tsv)

# Create blue slot and set ingress traffic to 0
az containerapp revision copy -n store-product-api -g $RG_NAME -i $ACR_LOGIN_SERVER/productapi:latest
az containerapp ingress traffic set -n store-product-api -g $RG_NAME --revision-weight $CURRENT_REVISION=100

# Get Blue Slot URL
BLUE_SLOT_URL=$(az containerapp revision list -g $RG_NAME -n store-product-api --query 'reverse(sort_by([].{Revision:name,Replicas:properties.replicas,Active:properties.active,Created:properties.createdTime,FQDN:properties.fqdn}[?Active!=`false`], &Created))| [0].FQDN' -o tsv)

# cd into Integration Tests, and pass in URL to run them
dotnet test --no-build --verbosity normal  --logger trx --environment BLUE_SLOT_URL="$BLUE_SLOT_URL/products"

# 'Promote' the blue slot to green by setting ingress to 100
az containerapp ingress traffic set -n store-product-api -g $RG_NAME --revision-weight $BLUE_SLOT_URL=100
