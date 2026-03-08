# Install terraform:
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
terraform -version

# Install Azure CLI (with only one command)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
az account show

# Register Microsoft.App
az provider register --namespace Microsoft.App
# Check (can last up to 30 seconds):
az provider show --namespace Microsoft.App --query registrationState
az provider show --namespace Microsoft.DBForMySQL --query registrationState

# terraform use:
terraform init
terraform validate
terraform plan
terraform plan --out example.plan
terraform apply example.plan
terraform apply -auto-approve
# With maximum debugging:
TF_LOG=DEBUG terraform apply -no-color 2>&1 | tee terraform_complete.log
# Destroy all resources
terraform destroy

terraform show
terraform state list

# Download infracost (for estimating infrastructure costs):
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
infracost auth login

# Commands:
infracost breakdown --path=.
