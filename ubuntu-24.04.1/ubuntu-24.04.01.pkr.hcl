# https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox/latest/components/builder/iso
# based on https://github.com/ChristianLempa/boilerplates/blob/main/packer/proxmox/ubuntu-server-noble/ubuntu-server-noble.pkr.hcl

# Resource Definition for the VM Template

packer {
  required_plugins {
    name = {
      version = "~> 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "ubuntu-24-04-1" {
  proxmox_url = "${var.proxmox_api_url}"      # PROXMOX_URL
  username    = "${var.proxmox_api_token_id}" # PROXMOX_USERNAME
  # password    = "${var.proxmox_password}"              # PROXMOX_PASSWORD
  token = "${var.proxmox_api_token_secret}" # PROXMOX_TOKEN

  insecure_skip_tls_verify = true

  node = "pve1"
  # pool                 = ""
  task_timeout = "1m"
  vm_name      = "ubuntu-24.04.1"
  # vm_id                = "999"
  template_name        = "ubuntu-24.04-${var.cores}-${var.memory}M-${var.disk_size}"
  tags                 = "ubuntu-noble-numbat;template"
  template_description = "Noble Numbat"
  os                   = "l26"
  # bios                 = "seabios"

  # efi_config {
  #   efi_storage_pool  = "local",
  #   pre_enrolled_keys = true,
  #   efi_format        = "raw",
  #   efi_type          =  "4m"
  # }

  boot_iso {
    type             = "scsi"
    iso_storage_pool = "local"
    iso_file         = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
    unmount          = true
    iso_checksum     = "sha256:e240e4b801f7bb68c20d1356b60968ad0c33a41d00d828e74ceb3364a0317be9"
  }

  qemu_agent = true
  # qemu_additional_args = "-no-reboot -smbios type=0,vendor=FOO"

  scsi_controller = "virtio-scsi-pci"

  onboot = false

  disable_kvm = false

  disks {
    disk_size           = "${var.disk_size}"
    format              = "raw"
    storage_pool        = "local-zfs"
    type                = "virtio"
    cache_mode          = "none"
    io_thread           = false
    exclude_from_backup = false
  }

  cores = "${var.cores}"
  # cpu_type = "kvm64"
  # sockets = "1"

  memory = "${var.memory}"
  # ballooning_minimum = ""

  # vga {
  #   type   = "vmware",
  #   memory = 32
  # }

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
    mtu      = 0
    # mac_address = ""
    # vlan_tag = "yes"
  }

  # pci_devices {
  #   host          = "0000:0d:00.1"
  #   pcie          = false
  #   device_id     = "1003"
  #   legacy_igd    = false
  #   mdev          = "some-model"
  #   hide_rombar   = false
  #   romfile       = "vbios.bin"
  #   sub_device_id = ""
  #   sub_vendor_id = ""
  #   vendor_id     = "15B3"
  #   x_vga         = false
  # }


  cloud_init              = true
  cloud_init_storage_pool = "local-zfs"
  cloud_init_disk_type    = "scsi"

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]

  boot      = "c"
  boot_wait = "5s"
  # boot_key_interval = "1h5m2s"

  # PACKER Autoinstall Settings
  http_directory = "./http"
  #http_bind_address = "10.1.149.166"
  # (Optional) Bind IP Address and Port
  # http_port_min = 8802
  # http_port_max = 8802

  ssh_username = "ubuntu"

  # (Option 1) Add your Password here
  ssh_password = "${var.ssh_password}"
  # - or -
  # (Option 2) Add your Private SSH KEY file here
  # ssh_private_key_file = "~/.ssh/id_rsa"

  # Raise the timeout, when installation takes longer
  ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

  name    = "ubuntu-noble-numbat"
  sources = ["proxmox-iso.ubuntu-24-04-1"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt-get -y autoremove --purge",
      "sudo apt-get -y clean",
      "sudo apt-get -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync"
    ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

}
