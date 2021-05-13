## <https://www.terraform.io/docs/providers/azurerm/index.html>
provider "azurerm" {
  version = "=2.5.0"
  features {}
}

## <https://www.terraform.io/docs/providers/azurerm/r/resource_group.html>
resource "azurerm_resource_group" "terraformrg" {
  name     = "terraformrg"
  location = "eastus"
}


## <https://www.terraform.io/docs/providers/azurerm/r/virtual_network.html>
resource "azurerm_virtual_network" "terraformvNetjump" {
  name                = "terraformvNetjump"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.terraformrg.location
  resource_group_name = azurerm_resource_group.terraformrg.name
}



## <https://www.terraform.io/docs/providers/azurerm/r/subnet.html> 
resource "azurerm_subnet" "subnet1jump" {
  name                 = "jump"
  resource_group_name  = azurerm_resource_group.terraformrg.name
  virtual_network_name = azurerm_virtual_network.terraformvNetjump.name
  address_prefix       = "192.168.1.0/24"
}

## <https://www.terraform.io/docs/providers/azurerm/r/subnet.html> 
resource "azurerm_subnet" "subnet2AD" {
  name                 = "AD"
  resource_group_name  = azurerm_resource_group.terraformrg.name
  virtual_network_name = azurerm_virtual_network.terraformvNetjump.name
  address_prefix       = "192.168.2.0/24"
}

## <https://www.terraform.io/docs/providers/azurerm/r/subnet.html> 
resource "azurerm_subnet" "subnet3tools" {
  name                 = "tools"
  resource_group_name  = azurerm_resource_group.terraformrg.name
  virtual_network_name = azurerm_virtual_network.terraformvNetjump.name
  address_prefix       = "192.168.3.0/24"
}

## <https://www.terraform.io/docs/providers/azurerm/r/network_interface.html>
resource "azurerm_network_interface" "terraformvNetAD1" {
  name                = "terraformvNetAD1"
  location            = azurerm_resource_group.terraformrg.location
  resource_group_name = azurerm_resource_group.terraformrg.name

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.subnet2AD.id
    private_ip_address_allocation = "Dynamic"
  }
}

# <https://www.terraform.io/docs/providers/azurerm/r/network_interface.html>
resource "azurerm_network_interface" "terraformvNetjump1" {
  name                = "terraformvNetjump1"
  location            = azurerm_resource_group.terraformrg.location
  resource_group_name = azurerm_resource_group.terraformrg.name

  ip_configuration {
    name                          = "internal2"
    subnet_id                     = azurerm_subnet.subnet1jump.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.jump-public.id
  }
}

# <https://www.terraform.io/docs/providers/azurerm/r/network_interface.html>
resource "azurerm_network_interface" "terraformvNettools1" {
  name                = "terraformvNettools1"
  location            = azurerm_resource_group.terraformrg.location
  resource_group_name = azurerm_resource_group.terraformrg.name

  ip_configuration {
    name                          = "internal3"
    subnet_id                     = azurerm_subnet.subnet3tools.id
    private_ip_address_allocation = "Dynamic"
  }
}

## <https://www.terraform.io/docs/providers/azurerm/r/windows_virtual_machine.html>
resource "azurerm_windows_virtual_machine" "AD" {
  name                = "AD-machine"
  resource_group_name = azurerm_resource_group.terraformrg.name
  location            = azurerm_resource_group.terraformrg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  #availability_set_id = azurerm_availability_set.DemoAset.id
  network_interface_ids = [azurerm_network_interface.terraformvNetAD1.id]

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

## <https://www.terraform.io/docs/providers/azurerm/r/windows_virtual_machine.html>
resource "azurerm_windows_virtual_machine" "jump" {
  name                = "jump-machine"
  resource_group_name = azurerm_resource_group.terraformrg.name
  location            = azurerm_resource_group.terraformrg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
 # availability_set_id = azurerm_availability_set.DemoAset.id
  network_interface_ids = [azurerm_network_interface.terraformvNetjump1.id]

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

## <https://www.terraform.io/docs/providers/azurerm/r/windows_virtual_machine.html>
resource "azurerm_windows_virtual_machine" "tools" {
  name                = "tools-machine"
  resource_group_name = azurerm_resource_group.terraformrg.name
  location            = azurerm_resource_group.terraformrg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
#  availability_set_id = azurerm_availability_set.DemoAset.id
  network_interface_ids = [azurerm_network_interface.terraformvNettools1.id]

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



resource "azurerm_app_service_plan" "appservice" {
  name                = "terraform-appserviceplan"
  location            = azurerm_resource_group.terraformrg.location
  resource_group_name = azurerm_resource_group.terraformrg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "terraformdbapp" {
  name                = "terraformdbapp"
  location            = azurerm_resource_group.terraformrg.location
  resource_group_name = azurerm_resource_group.terraformrg.name
  app_service_plan_id = azurerm_app_service_plan.appservice.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
  }
}


resource "azurerm_virtual_network" "appgateway-public" {
  name                = "appgatway-network"
  resource_group_name = azurerm_resource_group.terraformrg.name
  location            = azurerm_resource_group.terraformrg.location
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.terraformrg.name
  virtual_network_name = azurerm_virtual_network.appgateway-public.name
  address_prefix     = "10.254.0.0/24"
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.terraformrg.name
  virtual_network_name = azurerm_virtual_network.appgateway-public.name
  address_prefix     = "10.254.2.0/24"
}

resource "azurerm_public_ip" "gateway" {
  name                = "gateway-pip"
  resource_group_name = azurerm_resource_group.terraformrg.name
  location            = azurerm_resource_group.terraformrg.location
  allocation_method   = "Dynamic"
}

#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.appgateway-public.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.appgateway-public.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.appgateway-public.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.appgateway-public.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.appgateway-public.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.appgateway-public.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.appgateway-public.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "network-appgateway"
  resource_group_name = azurerm_resource_group.terraformrg.name
  location            = azurerm_resource_group.terraformrg.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

resource "azurerm_storage_account" "terraform-teststorage" {
  name                     = "storageaccountnst1"
  resource_group_name      = azurerm_resource_group.terraformrg.name
  location                 = azurerm_resource_group.terraformrg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_network_security_group" "AD-nsg" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.terraformrg.location
  resource_group_name = azurerm_resource_group.terraformrg.name
}

resource "azurerm_network_security_rule" "AD-nsg" {
  name                        = "AD"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terraformrg.name
  network_security_group_name = azurerm_network_security_group.AD-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "AD" {
  subnet_id                 = azurerm_subnet.subnet2AD.id
  network_security_group_id = azurerm_network_security_group.AD-nsg.id
}

resource "azurerm_network_security_group" "jump-nsg" {
  name                = "acceptanceTestSecurityGroup2"
  location            = azurerm_resource_group.terraformrg.location
  resource_group_name = azurerm_resource_group.terraformrg.name
}

resource "azurerm_network_security_rule" "jump-nsg" {
  name                        = "jump"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terraformrg.name
  network_security_group_name = azurerm_network_security_group.jump-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "jump" {
  subnet_id                 = azurerm_subnet.subnet1jump.id
  network_security_group_id = azurerm_network_security_group.jump-nsg.id
}

resource "azurerm_network_security_group" "tools-nsg" {
  name                = "acceptanceTestSecurityGroup3"
  location            = azurerm_resource_group.terraformrg.location
  resource_group_name = azurerm_resource_group.terraformrg.name
}

resource "azurerm_network_security_rule" "tools-nsg" {
  name                        = "tools"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terraformrg.name
  network_security_group_name = azurerm_network_security_group.tools-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "tools" {
  subnet_id                 = azurerm_subnet.subnet3tools.id
  network_security_group_id = azurerm_network_security_group.tools-nsg.id
}

resource "azurerm_sql_server" "sql-server" {
  name                         = "mysqlserverterraformrfg"
  resource_group_name          = azurerm_resource_group.terraformrg.name
  location                     = "West US"
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"

  tags = {
    environment = "production"
  }
}



resource "azurerm_sql_database" "sql-database" {
  name                = "mysqldatabase"
  resource_group_name = azurerm_resource_group.terraformrg.name
  location            = "West US"
  server_name         = azurerm_sql_server.sql-server.name

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.terraform-teststorage.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.terraform-teststorage.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }



  tags = {
    environment = "production"
  }
}

resource "azurerm_public_ip" "jump-public" {
  name                = "jump-public"
  resource_group_name = azurerm_resource_group.terraformrg.name
  location            = azurerm_resource_group.terraformrg.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
