# Packer Templates for Proxmox Virtual Environment

## Usage

### Before run please create `variables.pkrvars.hcl`

### Example of `variables.pkrvars.hcl`

```hcl
proxmox_api_token_secret = "<your_token_here>"
ssh_username = "ubuntu"
ssh_password = "ubuntu"
code_name = "noble"
ubuntu_version = "24.04.2"
cores = "1"
memory = "2048"
disk_size = "40G"
```

### Install required plugin

```bash
packer plugins install github.com/hashicorp/proxmox
```

### Create a template

```bash
cd ubuntu-24.04.1/
packer build --var-file variables.pkrvars.hcl .
```

To create a VM Template prepared for running as k8s node uncomment [this](https://github.com/yulyangi/proxmox-packer-templates/blob/master/ubuntu-24.04.1/ubuntu-24.04.01.pkr.hcl#L173-L176) block of code
