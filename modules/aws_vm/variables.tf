# terraform/modules/aws/variables.tf

variable "vm_name" {
  description = "Name tag for the VM"
  type        = string
}

variable "ami" {
  description = "AMI ID to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "disk_size_gb" {
  description = "Size of the root disk"
  type        = number
  default     = 64
}