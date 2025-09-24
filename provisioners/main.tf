locals {
  resource_group_name = "test-tf"
  location_name = "West Europe"

  virtual_network = {
    name = "vnet-test-tf"
    address_space = "10.0.0.0/16"
  }
  subnet = [
    {
      name = "appsubnet"
      address_prefix = "10.0.1.0/24"
    },
    {
      name = "dbsubnet"
      address_prefix = "10.0.2.0/24"
    }
  ]
}

resource "azurerm_resource_group" "resource_tf" {
  name     = local.resource_group_name
  location = local.location_name
}

resource "azurerm_virtual_network" "vnet_details" {
  name                = local.virtual_network.name
  location            = local.location_name
  resource_group_name = local.resource_group_name
  address_space       = [local.virtual_network.address_space]

  depends_on = [ azurerm_resource_group.resource_tf ]
}

resource "azurerm_subnet" "appsubnet_details" {
  name                 = local.subnet[0].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnet[0].address_prefix]

  depends_on = [ azurerm_virtual_network.vnet_details ]
}

resource "azurerm_subnet" "dbsubnet_details" {
  name                 = local.subnet[1].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnet[1].address_prefix]

  depends_on = [azurerm_virtual_network.vnet_details]

}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.resource_tf.location
  resource_group_name = azurerm_resource_group.resource_tf.name

  security_rule {
  name                       = "SSH"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "203.0.113.10"  # Replace with YOUR IP
  destination_address_prefix = "*"
}


  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_public_ip" "vm_public_ip" {
  name                         = "vm-public-ip"
  location                     = local.location_name
  resource_group_name          = local.resource_group_name
  allocation_method            = "Static"
  idle_timeout_in_minutes     = 4
}
output "public_ip_address" {
  value = azurerm_public_ip.vm_public_ip.ip_address
}


resource "azurerm_network_interface" "nic_details" {
  name                = "nictf"
  location            = local.location_name
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.appsubnet_details.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}
//output variables
output "app_subnet_id" {
  value = azurerm_subnet.appsubnet_details.id
}

resource "null_resource" "deployment_prep" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo Deployment started at ${timestamp()} > deployment-${replace(timestamp(), ":", "-")}.log"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                             = "slazdemo01"
  resource_group_name              = local.resource_group_name
  location                         = local.location_name
  size                             = "Standard_B1s"
  admin_username                   = "adminuser"
  admin_password                   = "Admin@123"
  network_interface_ids           = [azurerm_network_interface.nic_details.id]
  depends_on = [ null_resource.deployment_prep ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
     }
  os_disk {
    name                 = "test-vm-os-disk"  # Custom name for the OS disk
    caching              = "ReadWrite"       # Caching options: ReadOnly, ReadWrite, None
    storage_account_type = "Standard_LRS"    # Storage type: Standard_LRS, Premium_LRS, etc.
    disk_size_gb         = 30               # OS disk size in GB
  }
  disable_password_authentication = false
#   depends_on = [azurerm_network_interface.nic_details]  # Explicit dependency


    provisioner "remote-exec" {
    inline = [   
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      
      # Create a sample welcome page
      "echo '<html><body><h1>#28daysofAZTerraform is Awesome!</h1></body></html>' | sudo tee /var/www/html/index.html",
      
      # Ensure nginx is running
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx" ]

      connection {
        type = "ssh"
        user = "aadminuser"
        password = "Admin@123"
        host = azurerm_public_ip.vm_public_ip.ip_address
      }
    
  }

    provisioner "file" {
    source = "configs/sample.conf"
    destination = "/home/azureuser/sample.conf"

    connection {
        type = "ssh"
        user = "adminuser"
        password = "Admin@123"
        host = azurerm_public_ip.vm_public_ip.ip_address
      }
    
  }

}
