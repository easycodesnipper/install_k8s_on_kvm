
![Project Logo](images/installer.svg)

One-Key to install Kubernetes cluster on KVM guest machines leveraged by Infrastructure as Code tools Terraform and Ansible

```bash
### Install fresh Kubernetes cluster, this will provision guest vms infrastructure and install kubernetes
total_nodes=<N> ./install.sh # The first node is master, the remaining nodes are workers, if not specified, N is 3 by default.

### Reserve existing infrastructure and reset and reinstall Kubernetes cluster
provision_infra=false ./install.sh -e k8s_reset=true
```

### By default using NAT model
### for bridge network mode, to create bridge network on the host is required
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
- `provision_reset=${provision_reset:-false}`
- `skip_cleanup_confirm=${skip_cleanup_confirm:-false}`

Usage:
```bash
[<key1=value1> <key2=value2> ...] ./install.sh
```

### Supported install options
- `-e docker_version: "20.10.7"`
- `docker_mirror: "" # Aliyun or AzureChinaCloud supported`
- `-e k8s_version: "1.31.2"`
- `-e k8s_repo_uri: "https://pkgs.k8s.io"`
- `-e k8s_cidr: "10.244.0.0/16"`
- `-e k8s_cni: flannel` # flannel or calico is supported
- `-e k8s_metric_server_enabled: false` # if install metric server
- `-e k8s_reset: false` # if reset exising kubernetes
- `-e k8s_calico_version: "3.28.2"`
- `-e k8s_flannel_version: "0.26.0"`
- `-e metric_server_version: "0.7.2"`

Usage:
```bash
./install [-e <key1=value1> -e <key2=value2>... ]
```

The provision options and install options can be used together as follows.
```bash
[<key1=value1> <key2=value2> ...] ./install.sh [-e <key3=value3> -e <key4=value4>... ]
```

Due to notorious(臭名昭著) *[GFW](https://en.wikipedia.org/wiki/Great_Firewall)*, some images cannot pulled in China, here is the workaround.
```bash
network_mode=bridge ./install.sh \
-e docker_mirror="Aliyun" \
-e k8s_repo_uri="https://mirrors.aliyun.com/kubernetes-new" \
-e k8s_gcr="registry.cn-hangzhou.aliyuncs.com/google_containers"
```
