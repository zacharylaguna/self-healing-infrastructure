provider "aws" {
  region = "us-east-2"
}

# Security group to allow SSH
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh_and_ping"
  description = "Allow SSH and ICMP (ping) inbound traffic"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ICMP (ping)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance running Ubuntu 24.04
resource "aws_instance" "ubuntu_vm" {
  ami                    = "ami-04f167a56786e4b09"  # Ubuntu 24.04 LTS (x86) in us-east-2
  instance_type          = "t2.micro"
  key_name               = "dev-machine"
  security_groups        = [aws_security_group.ssh_access.name]

  root_block_device {
    volume_size           = 64
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name = "self-healing-machine1"
  }
}

# Route 53 DNS record
resource "aws_route53_record" "dns_record" {
  zone_id = "Z02235953VIBHTG0E4L92"
  name    = "self-healing-machine1.dev-machine.link"
  type    = "A"
  ttl     = 300

  records = [aws_instance.ubuntu_vm.public_ip]
}
