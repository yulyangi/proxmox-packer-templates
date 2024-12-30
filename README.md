### Packer Templates for Proxmox Virtual Environment
Put token in `variables.pkrvars.hcl` as `proxmox_api_token_secret = "<your_token>"`
```
packer plugins install github.com/hashicorp/proxmox
packer build --var-file variables.pkrvars.hcl .
```

To create a VM Template prepared for running as k8s node uncomment [this](https://github.com/yulyangi/proxmox-packer-templates/blob/master/ubuntu-24.04.1/ubuntu-24.04.01.pkr.hcl#L173-L176) block of code
