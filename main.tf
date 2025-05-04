# terraform/main.tf

provider "aws" {
  region = "us-east-2"
}

provider "azurerm" {
  features {}
  subscription_id = "640aa3a4-489e-4f28-8e6e-433b2f884997"
}

# AWS VMs
module "aws_vms" {
  source         = "./modules/aws_vm"
  for_each       = toset(var.aws_vm_names)
  vm_name        = each.key
  ami            = var.aws_ami
  instance_type  = var.aws_instance_type
  key_name       = var.aws_key_name
  disk_size_gb   = var.disk_size_gb
}

# Azure VMs
module "azure_vms" {
  source             = "./modules/azure_vm"
  for_each           = toset(var.azure_vm_names)
  vm_name            = each.key
  resource_group     = var.azure_resource_group
  vnet_name          = var.azure_vnet_name
  subnet_name        = var.azure_subnet_name
  ssh_key_name       = var.azure_ssh_key_name
  vm_size            = var.azure_instance_type
  disk_size_gb       = var.disk_size_gb
}

module "dns_records_aws" {
  source     = "./modules/dns_record"
  for_each   = { for name, mod in module.aws_vms : name => mod.public_ip }

  name       = "${each.key}.dev-machine.link"
  ip_address = each.value
  zone_id    = var.route53_zone_id
}

module "dns_records_azure" {
  source     = "./modules/dns_record"
  for_each   = { for name, mod in module.azure_vms : name => mod.public_ip }

  name       = "${each.key}.dev-machine.link"
  ip_address = each.value
  zone_id    = var.route53_zone_id
}
