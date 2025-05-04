# terraform/outputs.tf

output "aws_vm_ips" {
  value = { for name, mod in module.aws_vms : name => mod.public_ip }
}

output "azure_vm_ips" {
  value = { for name, mod in module.azure_vms : name => mod.public_ip }
}