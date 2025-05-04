# terraform/modules/dns_record/outputs.tf

output "fqdn" {
  description = "Fully qualified domain name of the record"
  value       = aws_route53_record.a_record.fqdn
}

output "ip_address" {
  description = "Resolved IP address assigned to the record"
  value       = aws_route53_record.a_record.records
}