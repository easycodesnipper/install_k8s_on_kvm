
![Project Logo](images/installer.svg)

One-Key to install Kubernetes cluster on KVM guest machines leveraged by Infrastructure as Code tools Terraform and Ansible

```bash
### Install fresh Kubernetes cluster
./install.sh 

### Reset existing Kubernetes cluster and reinstall
provision_infra=false ./install.sh -e k8s_reset=true
```
### For bridge network mode
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
      interfaces: [ enp0s25 ]  # Attach eth0 (or enp0s25) to the bridge
      dhcp4: true  # Enable DHCP on the bridge interface
      dhcp6: false  # Disable IPv6 DHCP (optional)
      routes:
        - to: default
          via: 192.168.3.1  # Default gateway (router IP)
          metric: 100
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]  # DNS servers (Google DNS)
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
# DHCP configuration for network 192.168.4.0/24 (for br0 interface), change with yours ips
subnet 192.168.4.0 netmask 255.255.255.0 {
  range 192.168.4.10 192.168.4.100;    # DHCP IP range for VMs
  option domain-name-servers 8.8.8.8, 8.8.4.4;  # DNS servers for VMs
  option routers 192.168.4.5;  # Default gateway (usually the bridge IP)
  option broadcast-address 192.168.4.255;  # Broadcast address
  default-lease-time 600;  # Default lease time in seconds
  max-lease-time 7200;  # Maximum lease time in seconds
}
...

# Set the INTERFACESv4 variable to your network interface name
sudo vim /etc/default/isc-dhcp-server
INTERFACESv4="br0"

# Enable and start DHCP server
sudo systemctl enable --now isc-dhcp-server

# Install with bridge mode
network_mode=bridge ./install.sh
```

