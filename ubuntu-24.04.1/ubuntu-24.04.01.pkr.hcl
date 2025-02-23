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

source "proxmox-iso" "ubuntu" {
  proxmox_url = "${var.proxmox_api_url}"      # PROXMOX_URL
  username    = "${var.proxmox_api_token_id}" # PROXMOX_USERNAME
  # password    = "${var.proxmox_password}"   # PROXMOX_PASSWORD
  token = "${var.proxmox_api_token_secret}"   # PROXMOX_TOKEN

  insecure_skip_tls_verify = true

  node                 = "pve1"
  task_timeout         = "1m"
  vm_name              = "ubuntu-${var.code_name}-${var.ubuntu_version}"
  template_name        = "ubuntu-${var.code_name}-${var.ubuntu_version}-${var.cores}-${var.memory}M-${var.disk_size}"
  tags                 = "ubuntu;template"
  template_description = "${var.code_name}-${var.ubuntu_version}"
  os                   = "l26"
  # vm_id               = "999"
  # pool                 = "rpool"
  # bios                = "seabios"

  # efi_config {
  #   efi_storage_pool  = "local",
  #   pre_enrolled_keys = true,
  #   efi_format        = "raw",
  #   efi_type          =  "4m"
  # }

  boot_iso {
    type             = "scsi"
    iso_file         = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
    iso_checksum     = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
    unmount          = true
    # iso_url          = "https://releases.ubuntu.com/${var.code_name}/ubuntu-${var.ubuntu_version}-live-server-amd64.iso"
    # iso_checksum     = "d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
    # iso_storage_pool = "local"
  }

  qemu_agent = true
  # qemu_additional_args = "-no-reboot -smbios type=0,vendor=FOO"

  scsi_controller = "virtio-scsi-pci"

  onboot = false

  disable_kvm = false

  disks {
    type                = "virtio"
    storage_pool        = "local-zfs"

    disk_size           = "${var.disk_size}"
    format              = "raw"
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

  ssh_username = "${var.ssh_username}"

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
  sources = ["proxmox-iso.ubuntu"]

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

  # # Provisioning the VM Template as Kubernetes node in Proxmox #4
  # provisioner "shell" {
  #   script = "files/k8s-installations.sh"
  # }

}
