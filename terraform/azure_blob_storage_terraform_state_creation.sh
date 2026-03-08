# Create resource group
az group create --name rg-terraform-state --location "West Europe"

# Create storage account (name must be unique)
az storage account create \
    --name storblobexam123 \
    --resource-group rg-terraform-state \
    --location "West Europe" \
    --sku Standard_LRS

# Create container
az storage container create \
    --name terraform-state \
    --account-name storblobexam123