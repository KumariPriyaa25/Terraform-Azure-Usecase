resource "azurerm_resource_group" "rg" {
    name     = "test-rg"
    location = "canadaeast"

    tags = {
        environment = "prod"
        team = "automation"
    }
}
