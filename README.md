### Packer Templates for Proxmox Virtual Environment
###### Put token in variables.pkrvars.hcl as `proxmox_api_token_secret = "<your_token"`
```
packer plugins install github.com/hashicorp/proxmox
packer build --var-file variables.pkrvars.hcl .
```

###### To prepare VM Template prepared for running as k8s node uncomment this block of code
