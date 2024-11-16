resource "libvirt_network" "k8s_net" {
  name = "k8s_net"

  mode = var.network_mode

  # Conditional logic for the 'addresses' and 'bridge' attributes:
  addresses = var.network_mode == "nat" ? var.network_subnet : null
  bridge    = var.network_mode == "bridge" ? var.bridge_network : null

  mtu = var.network_mode == "nat" ? var.mtu : null

  domain = var.network_mode == "nat" ? var.domain : null

  dns {
    enabled    = true
    local_only = true
  }

  dhcp {
    enabled = true
  }
}
  
