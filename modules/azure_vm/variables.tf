# terraform/modules/azure/variables.tf

variable "vm_name" {}
variable "resource_group" {}
variable "vnet_name" {}
variable "subnet_name" {}
variable "ssh_key_name" {}
variable "vm_size" { default = "Standard_B1s" }
variable "disk_size_gb" { default = 64 }
