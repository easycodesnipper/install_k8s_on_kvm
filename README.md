
![Project Logo](images/installer.svg)

One-Key to install Kubernetes cluster on KVM guest machines leveraged by Infrastructure as Code tools Terraform and Ansible

```bash
### Install fresh Kubernetes cluster
./install.sh 

### Reset existing Kubernetes cluster and reinstall
provision_infra=false ./install.sh -e k8s_reset=true
```

### By default using NAT model, for bridge network mode, execute the following configurations. 
## Prerequisite
1. Create bridge network.
``` bash
sudo vim /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  version: 2
  renderer: networkd

  ethernets:
    enp0s25:
      optional: true
      dhcp4: false  # Don't request DHCP for the physical interface

  bridges:
    br0:
      optional: true
      interfaces: [ enp0s25 ]  # Attach eth0 (or enp0s25) to the bridge, replace network name with yours
      dhcp4: true  # Enable DHCP on the bridge interface
      dhcp6: false  # Disable IPv6 DHCP (optional)
      routes:
        - to: default
          via: 192.168.4.1  # Default gateway (router IP)
          metric: 100
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]  # DNS servers (Google DNS or other public DNS)
      parameters:
        stp: true  # Enable Spanning Tree Protocol (for loop prevention, optional)

```
``` bash
sudo netplan apply
```

2. A DHCP server is required to install on the host machine.

```bash
sudo apt update
sudo apt install isc-dhcp-server

# Configure isc-dhcp-server
sudo vim /etc/dhcp/dhcpd.conf
# Add below section
...
# An example to add DHCP configuration for subnet 192.168.4.0/24, replace with yours
subnet 192.168.4.0 netmask 255.255.255.0 {
  range 192.168.4.10 192.168.4.100;    # DHCP IP range for VMs
  option domain-name-servers 8.8.8.8, 8.8.4.4;  # DNS servers for VMs
  option routers 192.168.4.1;  # Default gateway
  option broadcast-address 192.168.4.255;  # Broadcast address
  default-lease-time 600;  # Default lease time in seconds
  max-lease-time 7200;  # Maximum lease time in seconds
}
...

# Set the INTERFACESv4 variable to your network interface name
sudo vim /etc/default/isc-dhcp-server
INTERFACESv4="br0" # replace with your bridge network name

# Enable and start DHCP server
sudo systemctl enable --now isc-dhcp-server
sudo systemctl status isc-dhcp-server

# Install with bridge network mode
network_mode=bridge ./install.sh
```

### Supported provision options
- `user=${user:-ubuntu}`
- `k8s_pool_path=${k8s_pool_path:-/mnt/data_lvm/k8s_pool}`
- `source_img_location=${source_img_location:-"https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"}`
- `boot_volume_size=${boot_volume_size:-10}` # in GB
- `data_volume_size=${data_volume_size:-20}` # in GB
- `vcpu_count=${vcpu_count:-2}`
- `memory_size=${memory_size:-2}` # in GB
- `total_nodes=${total_nodes:-3}` # By default, the first one is master
- `network_mode=${network_mode:-"nat"}`
- `provision_infra=${provision_infra:-true}`

Usage:
```bash
[<key1=value1> <key2=value2> ...] ./install.sh
```

### Supported install options
- `-e docker_version: "20.10.7"`
- `-e k8s_version: "1.31.2"`
- `-e k8s_minor_version: "{{ k8s_version | regex_replace('\\.\\d+$', '') }}"`
- `-e k8s_gpg_key: "https://pkgs.k8s.io/core:/stable:/v{{ k8s_minor_version }}/deb/Release.key"`
- `-e k8s_repo: "https://pkgs.k8s.io/core:/stable:/v{{ k8s_minor_version }}/deb/ /"`
- `-e k8s_cidr: "10.244.0.0/16"`
- `-e k8s_cni: flannel`
- `-e k8s_metric_server_enabled: false`
- `-e k8s_reset: false`

Usage:
```bash
./install [-e <key1=value1> -e <key2=value2>... ]
```

The provision options and install options can be used together as follows.
```bash
[<key1=value1> <key2=value2> ...] ./install.sh [-e <key3=value3> -e <key4=value4>... ]
```