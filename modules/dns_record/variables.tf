# terraform/modules/dns_record/variables.tf

variable "zone_id" {
  description = "Route 53 Hosted Zone ID"
  type        = string
}

variable "name" {
  description = "Fully qualified domain name"
  type        = string
}

variable "ip_address" {
  description = "Public IP address to associate with the A record"
  type        = string
}