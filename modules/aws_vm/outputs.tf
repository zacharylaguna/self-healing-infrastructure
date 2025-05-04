# terraform/modules/aws/outputs.tf

output "public_ip" {
  description = "Public IP address of the VM"
  value       = aws_instance.vm.public_ip
}