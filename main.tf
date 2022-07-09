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

resource "azurerm_resource_group" "test-rg" {
  name     = "test-resources"
  location = "West US 2"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "test-vn" {
  name                = "test-network"
  resource_group_name = azurerm_resource_group.test-rg.name
  location            = azurerm_resource_group.test-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    "environment" = "dev"
  }

}

resource "azurerm_subnet" "test-subnet" {
  name                 = "test-subnet"
  resource_group_name  = azurerm_resource_group.test-rg.name
  virtual_network_name = azurerm_virtual_network.test-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "test-sg" {
  name                = "test-sg"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name

  tags = {
    "environment" = "dev"
  }
}

resource "azurerm_network_security_rule" "test-dev-rule" {
  name                        = "test-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.test-rg.name
  network_security_group_name = azurerm_network_security_group.test-sg.name
}

resource "azurerm_subnet_network_security_group_association" "test-sga" {
  subnet_id                 = azurerm_subnet.test-subnet.id
  network_security_group_id = azurerm_network_security_group.test-sg.id
}

resource "azurerm_public_ip" "test-ip" {
  name                = "test-ip"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "test-nic" {
  name                = "test-nic"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test-ip.id
  }

  tags = {
    "environment" = "dev"
  }
}

resource "azurerm_windows_virtual_machine" "test-vm" {
  name                  = "test-vm"
  resource_group_name   = azurerm_resource_group.test-rg.name
  location              = azurerm_resource_group.test-rg.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  admin_password        = file("C:\\Users\\kenba\\azure_terraform_creds\\credential.txt")
  network_interface_ids = [azurerm_network_interface.test-nic.id]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}