#!/bin/bash -e

### Current workspace
work_dir=$(pwd)

### Variables definition
inventory_file="$work_dir/ansible/inventory.ini"
user=${user:-ubuntu}
k8s_pool_path=${k8s_pool_path:-/mnt/data_lvm/k8s_pool}
source_img_location=${source_img_location:-"https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"}
boot_volume_size=${boot_volume_size:-10} # in GB
data_volume_size=${data_volume_size:-20} # in GB
vcpu_count=${vcpu_count:-2}
memory_size=${memory_size:-2} # in GB
total_nodes=${total_nodes:-3} # By default, the first one will be taken as master
network_mode=${network_mode:-"nat"}
provision_reset=${provision_reset:-false}
skip_cleanup_confirm=${skip_cleanup_confirm:-false}

### Precheck the source image (download if it's a URL and update the source_img_location)
precheck_source_image() {
  # Function to check if the source is an HTTP, HTTPS, or FTP URL
  is_url() {
    [[ "$1" =~ ^(https?|ftp):// ]]
  }

  # If the source_img_location is an HTTP, HTTPS, or FTP URL
  if is_url "$source_img_location"; then
    # Define the local file path for storing the image
    local_file="/tmp/$(basename "$source_img_location")"
    
    # If file doesn't exist locally, download it
    if [[ ! -f "$local_file" ]]; then
      echo "OS image not found locally. Downloading from $source_img_location..."
      until curl -L -o "$local_file" "$source_img_location"; do
        sleep 5
      done
    else
      echo "File already exists locally at $local_file"
    fi

    # Update source_img_location to the local file path
    source_img_location="$local_file"

  # If the source_img_location is a local path
  elif [[ ! -f "$source_img_location" ]]; then
    echo "File $source_img_location not found locally."
    exit 1
  fi
}

### Terraform to provision infrastruce
function provision_infra() {
  local cleanup=false
  if [ "$provision_reset" = true ]; then
    cleanup=true
  elif [ -f "$work_dir/terraform/terraform.tfstate" ]; then
    if [ "$skip_cleanup_confirm" = false ]; then
      read -r -p "!!! Terraform provisioned existing infrastructure found, Keep to use it? [y/N]" response
      response="${response:-y}" # if the user presses Enter (empty input)
      case "$response" in
          [yY][eE][sS]|[yY])
              echo "Reserving to use existing infrastructure..."
              cleanup=false
              ;;
          [nN][oO]|[nN])
              cleanup=true
              ;;
          *)
              ;;
      esac
    fi
  fi

  if [ "$cleanup" = true ]; then
    echo "Cleanup existing infrastructure and re-create..."
    cleanup_infra
    echo "Provisioning cluster infrastructure..."
    precheck_source_image
    provision_infra_internal "$@"
  fi
}

function provision_infra_internal(){
    cd "$work_dir/terraform"
    if [ ! -d ".terraform" ]; then
        echo "Running terraform init..."
        terraform init
    else
        echo "Terraform is already initialized."
    fi
    terraform plan
    terraform apply \
    -var="user=$user" \
    -var="k8s_pool_path=$k8s_pool_path" \
    -var="source_img_location=$source_img_location" \
    -var="total_nodes=$total_nodes" \
    -var="boot_volume_size=$boot_volume_size" \
    -var="data_volume_size=$data_volume_size" \
    -var="vcpu_count=$vcpu_count" \
    -var="memory_size=$memory_size" \
    -var="network_mode=$network_mode" \
    -auto-approve
}

### Generate Ansible inventory.ini
function auto_gen_inventory() {
    cd "$work_dir/terraform"

    # Initialize an empty array for storing Hostname=IP pairs
    declare -A node_map
    for node in $(terraform output -json | jq -r '.k8s_cluster_nodes.value[] | "\(.hostname)=\(.ip)=\(.mac)"'); do
      hostname=$(echo "$node"|awk -F '=' '{print $1}')
      ip=$(echo "$node"|awk -F '=' '{print $2}')
      mac=$(echo "$node"|awk -F '=' '{print $3}')
      node_map[$hostname]="$ip=$mac"
    done

    # Create or overwrite the Ansible inventory
    echo "[k8s_master]" > "$inventory_file"

    # Get the first IP and hostname for the master node
    master_hostname=$(echo "${!node_map[@]}" | awk '{print $1}')
    master_ip=$(echo "${node_map[$master_hostname]}" | awk -F '=' '{print $1}')
    master_mac=$(echo "${node_map[$master_hostname]}" | awk -F '=' '{print $2}')
    echo "$master_ip ansible_host=$master_hostname ansible_ssh_host=$master_ip ansible_mac=$master_mac" >> "$inventory_file"

    # Add all worker IPs to the inventory (all except the master)
    echo -e "\n[k8s_workers]" >> "$inventory_file"
    for hostname in "${!node_map[@]}"; do
        if [[ "$hostname" != "$master_hostname" ]]; then
            ip=$(echo "${node_map[$hostname]}" | awk -F '=' '{print $1}')
            mac=$(echo "${node_map[$hostname]}" | awk -F '=' '{print $2}')
            echo "$ip ansible_host=$hostname ansible_ssh_host=$ip" ansible_mac=$mac>> "$inventory_file"
        fi
    done

    # Append the k8s_all children group
    cat <<EOL >> "$inventory_file"

[k8s_all:children]
k8s_master
k8s_workers
EOL
}

### Ansible playbook to install kvm on host
function playbook_install_kvm() {
    ansible_extra_vars=("$@")
    cd "$work_dir/ansible"
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i localhost, \
    --connection=local \
    -u "$USER" \
    kvm/install.yml \
    -vv \
    "${ansible_extra_vars[@]}"
}

### Ansible playbook to install kubernetes cluster on guests
function playbook_install_k8s() {
    ansible_extra_vars=("$@")
    cd "$work_dir/ansible"
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i inventory.ini \
    -u "$user" \
    kubernetes/install.yml \
    -vv \
    "${ansible_extra_vars[@]}"
}

### Cleanup existing provisioned infrastructure
function cleanup_infra() {
    cd "$work_dir/terraform"
    echo "Cleanup existing provisioned infrastructure..."
    terraform destroy -auto-approve
    echo "Terraform resources destroyed and state cleaned up."
    rm -rf "$work_dir/terraform/terraform.tfstate" \
           "$work_dir/terraform/terraform.tfstate.backup"
}

function main() {

    echo "##########################################################"
    echo "### Stage 1 -- Install KVM.............................###"
    echo "##########################################################"
    playbook_install_kvm "$@"

    echo "##############################################################"
    echo "### Stage 2 -- Terraform provisioning KVM infrastructure...###"
    echo "##############################################################"
    provision_infra "$@"

    echo "###############################################################################"
    echo "### Stage 3 -- Parse terraform output and Generate ansible inventory file...###"
    echo "###############################################################################"
    auto_gen_inventory "$@"

    echo "###############################################################"
    echo "### Stage 4 -- Run ansible playbook to install kubernetes...###"
    echo "###############################################################"
    playbook_install_k8s "$@"
}

main "$@"