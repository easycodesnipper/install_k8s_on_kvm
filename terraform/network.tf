resource "libvirt_network" "k8s_net" {
  name = "k8s_net"
  mode = "nat"

  addresses = ["192.168.100.0/24"]

  dns {
    enabled    = true
    local_only = true
  }

  dhcp {
    enabled = true
  }
}
