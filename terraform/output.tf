output "k8s_cluster_nodes" {
  value = [
    for i in range(length(libvirt_domain.k8s_node)) : {
      ip       = libvirt_domain.k8s_node[i].network_interface[0].addresses[0]
      hostname       = libvirt_domain.k8s_node[i].network_interface[0].hostname
    }
  ]
}
