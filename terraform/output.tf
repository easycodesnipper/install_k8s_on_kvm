output "k8s_cluster_ips" {
  value = [
    for i in range(length(libvirt_domain.k8s_node)) :
      length(libvirt_domain.k8s_node[i].network_interface) > 0 && 
      length(libvirt_domain.k8s_node[i].network_interface[0].addresses) > 0 ? 
      libvirt_domain.k8s_node[i].network_interface[0].addresses[0] : null
  ]
}
