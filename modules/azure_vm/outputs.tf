# terraform/modules/azure/outputs.tf

output "public_ip" {
  description = "Public IP of the Azure VM"
  value       = azurerm_public_ip.vm_ip.ip_address
}