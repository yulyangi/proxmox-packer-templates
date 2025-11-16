# Proxmox Packer Templates

A collection of Packer templates for creating Proxmox Virtual Environment VM templates.

## 📋 Prerequisites

- Proxmox VE 7.0 or later
- Packer 1.7.0 or later
- Proxmox API access with appropriate permissions
- The iso file needs to be manually downloaded

## 🚀 Quick Start

### 1. Install Required Packer Plugin

```bash
packer plugins install github.com/hashicorp/proxmox
```

### 2. Create a template

Update `variables.pkrvars.hcl` as needed.

```bash
cd ubuntu-24.04
packer build -var-file variables.pkrvars.hcl .
```

To create a VM Template prepared for running as k8s node uncomment `k8s-installations.sh` block of code
