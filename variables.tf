# terraform/variables.tf

variable "aws_ami" {
  default = "ami-04f167a56786e4b09"
}

variable "aws_instance_type" {
  default = "t2.micro"
}

variable "aws_key_name" {
  default = "dev-machine"
}

variable "disk_size_gb" {
  default = 64
}

variable "azure_resource_group" {
  default = "Subscription1-RG"
}

variable "azure_vnet_name" {
  default = "Subscription1-VNET"
}

variable "azure_subnet_name" {
  default = "default"
}

variable "azure_ssh_key_name" {
  default = "dev-machine"
}

variable "azure_instance_type" {
  default = "Standard_B1s"
}

variable "route53_zone_id" {
  description = "AWS Route 53 Hosted Zone ID"
  default     = "Z02235953VIBHTG0E4L92"
}

variable "aws_vm_names" {
  description = "List of AWS VM names to create"
  type        = list(string)
}

variable "azure_vm_names" {
  description = "List of Azure VM names to create"
  type        = list(string)
}
