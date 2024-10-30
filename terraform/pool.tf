resource "libvirt_pool" "k8s_pool" {
  name = "k8s_pool"
  type = "dir"
  target {
    path = var.k8s_pool_path
  }
}