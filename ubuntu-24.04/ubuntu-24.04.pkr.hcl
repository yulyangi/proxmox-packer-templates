# https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox/latest/components/builder/iso

packer {
  required_plugins {
    name = {
      version = "~> 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_host" {
  type = string
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "proxmox_api_user" {
  type = string
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable iso_file {
  type = string
}

variable iso_sha {
  type = string
}

variable "cores" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "disk_size" {
  type    = string
  default = "20G"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

source "proxmox-iso" "ubuntu" {
  proxmox_url = "https://${var.proxmox_host}/api2/json" # PROXMOX_URL
  username    = "${var.proxmox_api_user}"               # PROXMOX_USERNAME
  token       = "${var.proxmox_api_token}"              # PROXMOX_TOKEN

  insecure_skip_tls_verify = true

  node                 = "pve"
  task_timeout         = "1m"
  vm_name              = "ubuntu-noble-24.04"
  template_name        = "ubuntu-noble-24.04-${var.cores}-${var.memory}M-${var.disk_size}"
  tags                 = "ubuntu;template"
  template_description = "noble-24.04"
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
    iso_file         = "${var.iso_file}"
    iso_checksum     = "${var.iso_sha}"
    unmount          = true
    iso_storage_pool = "local"
  }

  additional_iso_files {
    cd_files = [
      "./http/meta-data",
      "./http/user-data"
    ]
    cd_label         = "cidata"
    iso_storage_pool = "local"
    unmount          = true
  }

  qemu_agent = true
  # qemu_additional_args = "-no-reboot -smbios type=0,vendor=FOO"

  scsi_controller = "virtio-scsi-pci"

  onboot = false

  disable_kvm = false

  disks {
    type         = "virtio"
    storage_pool = "${var.storage_pool}"

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
    mtu      = 1
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
  cloud_init_storage_pool = "${var.storage_pool}"
  cloud_init_disk_type    = "scsi"

  boot_command = [
    "c", "<wait3s>",
    "linux /casper/vmlinuz --- autoinstall s=/cidata/", "<enter><wait3s>",
    "initrd /casper/initrd", "<enter><wait3s>",
    "boot", "<enter>"
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
  # ssh_private_key_file = "~/.ssh/id_ed25519_proxmox"

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
