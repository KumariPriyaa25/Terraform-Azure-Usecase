variable "location" {
  type = list(string)
  default = [ "eastus", "westus" ]
}
variable "vm_size" {
    type = list(string)
    default = ["Standard_B2s", "Standard_B2ms"]
}
variable "allowed_tags" {
    type = list(string)
    default = ["environment", "team"]
}