resource "libvirt_volume" "source_img" {
  count = var.total_nodes
  name   = "source-img-${count.index}"
  pool   = libvirt_pool.k8s_pool.name
  source = var.source_img_location
  format = "qcow2"
}

resource "libvirt_volume" "boot_volume" {
  count          = var.total_nodes
  name           = "k8s-volume-boot-${count.index}"
  pool           = libvirt_pool.k8s_pool.name
  base_volume_id = libvirt_volume.source_img[count.index].id
  size           = var.boot_volume_size * 1024 * 1024 * 1024
}

resource "libvirt_volume" "data_volume" {
  count = var.total_nodes
  name  = "k8s-volume-data-${count.index}"
  pool  = libvirt_pool.k8s_pool.name
  size  = var.data_volume_size * 1024 * 1024 * 1024
}
