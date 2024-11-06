#!/bin/bash -e

work_dir=$(pwd)

### Variables definition
inventory_file="$work_dir/ansible/inventory.ini"
user=${user:-ubuntu}
k8s_pool_path=${k8s_pool_path:-/mnt/data_lvm/k8s_pool}
source_img_location=${source_img_location:-"https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"}
total_nodes=${total_nodes:-2} # By default, the first one will be taken as master
boot_volume_size=${boot_volume_size:-10} # in GB
data_volume_size=${data_volume_size:-20} # in GB
vcpu_count=${vcpu_count:-2}
memory_size=${memory_size:-2} # in GB


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
      echo "File not found locally. Downloading from $source_img_location..."
      curl -L -o "$local_file" "$source_img_location"
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
function provision_infra(){
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
    -auto-approve
}

### Generate Ansible inventory.ini
function auto_gen_inventory() {

    output=$(terraform output -json)

    # Extract the IP addresses using jq
    ips=($(echo "$output" | jq -r '.k8s_cluster_ips.value[]'))

    # Create or overwrite the Ansible inventory
    cat <<EOL > "$inventory_file"
[k8s_master]
${ips[0]}

[k8s_workers]
EOL

    # Add all worker IPs to the inventory
    for ip in "${ips[@]:1}"; do
        echo "$ip" >> "$inventory_file"
    done

    # Append the children group
    cat <<EOL >> "$inventory_file"

[k8s_all:children]
k8s_master
k8s_workers
EOL
}

### Ansible playbook to install kubernetes cluster
function playbook_install_k8s() {
    ansible_extra_vars=("$@")
    cd "$work_dir/ansible"
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i inventory.ini \
    -u $user \
    playbook.yml \
    -vv \
    "${ansible_extra_vars[@]}"
}

function main() {

    # precheck_source_image

    # provision_infra "$@"

    # auto_gen_inventory "$@"

    playbook_install_k8s "$@"
}

main "$@"