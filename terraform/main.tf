terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. RESOURCE GROUP
resource "azurerm_resource_group" "chat_rg" {
  name     = "cloud-chat-rg-v2"
  location = "Sweden Central" # Serwerownie w Holandii (blisko Polski, niski ping)
}

# 2. NETWORK (VNet i Subnet)
resource "azurerm_virtual_network" "chat_vnet" {
  name                = "chat-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.chat_rg.location
  resource_group_name = azurerm_resource_group.chat_rg.name
}

resource "azurerm_subnet" "chat_subnet" {
  name                 = "chat-subnet"
  resource_group_name  = azurerm_resource_group.chat_rg.name
  virtual_network_name = azurerm_virtual_network.chat_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. PUBLIC IP ADDRESS AND NETWORK CARD
resource "azurerm_public_ip" "chat_public_ip" {
  name                = "chat-public-ip"
  location            = azurerm_resource_group.chat_rg.location
  resource_group_name = azurerm_resource_group.chat_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "chat_nic" {
  name                = "chat-nic"
  location            = azurerm_resource_group.chat_rg.location
  resource_group_name = azurerm_resource_group.chat_rg.name

  ip_configuration {
    name                          = "chat-nic-config"
    subnet_id                     = azurerm_subnet.chat_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.chat_public_ip.id
  }
}

# 4. FIREWALL
resource "azurerm_network_security_group" "chat_nsg" {
  name                = "chat-nsg"
  location            = azurerm_resource_group.chat_rg.location
  resource_group_name = azurerm_resource_group.chat_rg.name

  # SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # 80 port and kubernetes ports
  security_rule {
    name                       = "HTTP_And_Chat"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "3000", "3001", "3002", "6443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Assigning Firewall to network card
resource "azurerm_network_interface_security_group_association" "chat_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.chat_nic.id
  network_security_group_id = azurerm_network_security_group.chat_nsg.id
}

# 5. SERWER (Ubuntu vm)
resource "azurerm_linux_virtual_machine" "chat_server" {
  name                = "chat-server-vm"
  resource_group_name = azurerm_resource_group.chat_rg.name
  location            = azurerm_resource_group.chat_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "ubuntu"

  network_interface_ids = [
    azurerm_network_interface.chat_nic.id,
  ]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# FINAL OUTPUT
output "SERVER_PUBLIC_IP" {
  value       = azurerm_public_ip.chat_public_ip.ip_address
  description = "Adres IP Twojego nowego potężnego serwera w Azure!"
}