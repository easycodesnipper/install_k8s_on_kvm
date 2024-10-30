output "k8s_cluster_ips" {
  value = [
    for i in range(var.total_nodes) :
    libvirt_domain.k8s_node[i].network_interface[0].addresses[0] if length(libvirt_domain.k8s_node[i].network_interface[0].addresses) > 0
  ]
}
