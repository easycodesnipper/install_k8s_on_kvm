#!/bin/bash -e

work_dir=$(pwd)

### Variables definition
inventory_file="$work_dir/ansible/inventory.ini"
user=${user:-ubuntu}
k8s_pool_path=${k8s_pool_path:-/mnt/data_lvm/k8s_pool}
source_img_location=${source_img_location:-/tmp/ubuntu-22.04-server-cloudimg-amd64.img}

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
    cd "$work_dir/ansible"
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
    -i inventory.ini \
    -u $user \
    playbook.yml \
    -vv
}

function main() {

    # provision_infra "$@"

    # auto_gen_inventory "$@"

    playbook_install_k8s "$@"
}

main "$@"