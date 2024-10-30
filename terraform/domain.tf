resource "libvirt_domain" "k8s_node" {
  count  = var.total_nodes
  name   = "k8s-node-${count.index == 0 ? "master" : count.index}"
  memory = var.memory_size * 1024
  vcpu   = var.vcpu_count

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(libvirt_volume.boot_volume.*.id, count.index)
  }

  disk {
    volume_id = element(libvirt_volume.data_volume.*.id, count.index)
  }

  network_interface {
    network_name   = libvirt_network.k8s_net.name
    wait_for_lease = true # Ensure to get ip in terraform output
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  provisioner "remote-exec" {
    inline = [
      "while ! nc -z ${self.network_interface[0].addresses[0]} 22; do",
      "  echo 'Waiting for SSH to become available...'",
      "  sleep 5",
      "done",
      "echo 'SSH is now available!'"
    ]

    connection {
      type        = "ssh"
      host        = self.network_interface[0].addresses[0]
      user        = var.user
      private_key = file(var.ssh_private_key)
      port        = 22
    }
  }
}
