variable "total_nodes" {
  description = "Total number of nodes (master + workers)"
  type        = number
  default     = 3
}

variable "user" {
  description = "The OS user or ssh user"
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key" {
  description = "The public SSH key for key-based authentication"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_public_key" {
  description = "The public SSH key for key-based authentication"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "k8s_pool_path" {
  description = "The pool path"
  type        = string
  default     = "/tmp"
}

variable "boot_volume_size" {
  description = "VM boot volume size in GB"
  type        = number
  default     = 10
}

variable "data_volume_size" {
  description = "VM data volume size in GB"
  type        = number
  default     = 10
}

variable "vcpu_count" {
  description = "CPU count"
  type        = number
  default     = 2
}

variable "memory_size" {
  description = "VM memory size in GB"
  type        = number
  default     = 2
}

variable "source_img_location" {
  description = "The OS source image download url"
  type = string
  default = "https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "cpu_mode" {
  description = "The CPU mode"
  type = string
  default = "host-passthrough"
}

variable "network_mode" {
  description = "The network mode nat or bridge"
  type = string
  default = "nat"
}

variable "domain" {
  description = "The network domain"
  type = string
  default = "k8s.local"
}

variable "mtu" {
  description = "The network mtu"
  type = number
  default = 1500
}

# if network_model is bridge, bridge network interface name is required
variable "bridge_network" {
  description = "The bridged network interface name"
  type = string
  default = "br0"
}

# if network_model is nat, subnet is required
variable "network_subnet" {
  description = "List of subnets for the network (e.g., ['192.168.100.0/24', '192.168.200.0/24'])"
  type        = list(string)
  default     = ["10.17.3.0/24"]
}

variable "autostart" {
  description = "If auto start vm and network"
  type = bool
  default = true
}