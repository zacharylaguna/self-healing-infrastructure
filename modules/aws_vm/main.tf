# terraform/modules/aws/main.tf

resource "aws_security_group" "vm_sg" {
  name        = "${var.vm_name}-sg"
  description = "Allow SSH and ICMP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

resource "aws_instance" "vm" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  security_groups        = [aws_security_group.vm_sg.name]

  root_block_device {
    volume_size = var.disk_size_gb
  }

  tags = {
    Name = var.vm_name
  }
}