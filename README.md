How to Use
🟩 Deploy to AWS
cd terraform/aws
terraform init && terraform apply

# Get the public IP
IP=$(terraform output -raw public_ip)
🟦 Or deploy to Azure
cd terraform/azure
terraform init && terraform apply

# Get the public IP
IP=$(terraform output -raw public_ip)
🌐 Update DNS
cd ../dns
terraform init
terraform apply -var="dns_ip=$IP"