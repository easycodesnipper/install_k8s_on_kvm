data "template_file" "user_data" {
  template = file("${path.module}/config/cloud_init.yml")
  count    = var.total_nodes
  vars = {
    ssh_authorized_keys = trimspace(file(var.ssh_public_key))
    user                = var.user
    hostname            = "k8s-node-${count.index == 0 ? "master" : count.index}"
    domain              = var.domain
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/config/network_config.yml")
  count    = var.total_nodes
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = format("cloudinit-%03d.iso", count.index)
  count          = var.total_nodes
  user_data      = data.template_file.user_data[count.index].rendered
  network_config = data.template_file.network_config[count.index].rendered
  pool           = libvirt_pool.k8s_pool.name
}
