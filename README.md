
![Project Logo](images/installer.svg)

One-Key to install Kubernetes cluster on KVM guest machines leveraged by Infrastructure as Code tools Terraform and Ansible

```bash
### Install fresh Kubernetes cluster
./install.sh 

### Reset existing Kubernetes cluster and reinstall
provision_infra=false ./install.sh -e k8s_reset=true
```
