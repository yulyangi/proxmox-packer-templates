### Packer Templates for Proxmox Virtual Environment
###### Put token in variables.pkrvars.hcl `proxmox_api_token_secret = "<your_token"`
```
packer plugins install github.com/hashicorp/proxmox
packer build --var-file variables.pkrvars.hcl .
```
