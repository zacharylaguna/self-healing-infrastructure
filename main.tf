# Variables
variable "cloud_provider" {
  description = "Which cloud provider to use: aws or azure"
  type        = string
  default     = "aws"
}

# AWS Provider
provider "aws" {
  region = "us-east-2"
}

# Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "640aa3a4-489e-4f28-8e6e-433b2f884997"
}

#----------------------------#
# AWS Resources
#----------------------------#

resource "aws_security_group" "ssh_access" {
  count       = var.cloud_provider == "aws" ? 1 : 0
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

resource "aws_instance" "ubuntu_vm" {
  count                  = var.cloud_provider == "aws" ? 1 : 0
  ami                    = "ami-04f167a56786e4b09"
  instance_type          = "t2.micro"
  key_name               = "dev-machine"
  security_groups        = [aws_security_group.ssh_access[0].name]

  root_block_device {
    volume_size = 64
  }

  tags = {
    Name = "self-healing-machine1"
  }
}

#----------------------------#
# Azure Resources
#----------------------------#

data "azurerm_resource_group" "rg" {
  name = "Subscription1-RG"
}

data "azurerm_virtual_network" "vnet" {
  name                = "Subscription1-VNET"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "subnet" {
  name                 = "default"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_ssh_public_key" "dev_key" {
  name                = "dev-machine"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "vm_nsg" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "self-healing-machine1-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-ICMP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "vm_public_ip" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "self-healing-machine1-ip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "vm_nic" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "self-healing-machine1-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "self-healing-machine1-ipconfig"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip[0].id
  }
}

resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  count                 = var.cloud_provider == "azure" ? 1 : 0
  name                  = "self-healing-machine1"
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.vm_nic[0].id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.dev_key.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Name = "self-healing-machine1"
  }
}

#----------------------------#
# DNS Records in Route 53
#----------------------------#

resource "aws_route53_record" "dns_record_aws" {
  count   = var.cloud_provider == "aws" ? 1 : 0
  zone_id = "Z02235953VIBHTG0E4L92"
  name    = "self-healing-machine1.dev-machine.link"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ubuntu_vm[0].public_ip]
}

resource "aws_route53_record" "dns_record_azure" {
  count   = var.cloud_provider == "azure" ? 1 : 0
  zone_id = "Z02235953VIBHTG0E4L92"
  name    = "self-healing-machine1.dev-machine.link"
  type    = "A"
  ttl     = 300

  records = [azurerm_public_ip.vm_public_ip[0].ip_address]

  depends_on = [azurerm_public_ip.vm_public_ip]

  lifecycle {
    ignore_changes = [records]
  }
}
