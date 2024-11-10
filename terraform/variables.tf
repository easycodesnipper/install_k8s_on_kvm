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