# terraform/modules/dns_record/main.tf

resource "aws_route53_record" "a_record" {
  zone_id = var.zone_id
  name    = var.name
  type    = "A"
  ttl     = 300
  records = [var.ip_address]
}