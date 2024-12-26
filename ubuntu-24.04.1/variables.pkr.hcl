variable "proxmox_api_url" {
  type    = string
  default = "https://pve1.yulyan.xyz:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type    = string
  default = "packer@pve!packer-token"
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
  default   = ""
}
