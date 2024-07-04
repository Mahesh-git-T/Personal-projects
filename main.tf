terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Azure_rg" {
  name     = "Dev_rg"
  location = ${var.location}
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "Azure_vn" {
  name                = "Dev_vn"
  resource_group_name = azurerm_resource_group.Azure_rg.name
  location            = azurerm_resource_group.Azure_rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "Azure_sub" {
  name                 = "Dev-subnet"
  resource_group_name  = azurerm_resource_group.Azure_rg.name
  virtual_network_name = azurerm_virtual_network.Azure_vn.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_network_security_group" "Azure_NSG" {
  name                = "DevNetworkSecurityGroup1"
  location            = azurerm_resource_group.Azure_rg.location
  resource_group_name = azurerm_resource_group.Azure_rg.name

  security_rule {
    name                       = "Dev_security_rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_subnet_network_security_group_association" "Azure_NSG_Association" {
  subnet_id                 = azurerm_subnet.Azure_sub.id
  network_security_group_id = azurerm_network_security_group.Azure_NSG.id
}

resource "azurerm_public_ip" "Azure_publicip" {
  name                = "DevPublicIp1"
  resource_group_name = azurerm_resource_group.Azure_rg.name
  location            = azurerm_resource_group.Azure_rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_network_interface" "Azure_NIC" {
  name                = "Dev-nic"
  location            = azurerm_resource_group.Azure_rg.location
  resource_group_name = azurerm_resource_group.Azure_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Azure_sub.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "Azure_vm" {
  name                = "Dev-vm-machine"
  resource_group_name = azurerm_resource_group.Azure_rg.name
  location            = azurerm_resource_group.Azure_rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.Azure_NIC.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

data "azurerm_public_ip" "ip_data" {
    name = azurerm_public_ip.Azure_publicip.name
    resource_group_name = azurerm_resource_group.Azure_rg.name
}

output "public_ip_address" {
    value = "${azurerm_linux_virtual_machine.Azure_vm.name}: ${data.azurerm_public_ip.ip_data.ip_address}"
}

