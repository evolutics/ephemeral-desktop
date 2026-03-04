packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "iso_checksum" {
  type    = string
  default = "sha256:3a4c9877b483ab46d7c3fbe165a0db275e1ae3cfe56a5657e5a47c2f99a99d1e"
}
variable "iso_version" {
  type    = string
  default = "24.04.4" # Update-worthy.
}
variable "password_hash" {
  type      = string
  sensitive = true
  default   = "6$wdAcoXrU039hKYPd$508Qvbe7ObUnxoj15DRCkzC3qO7edjH0VV7BPNRDYK4QR8ofJaEEF2heacn0QgD.f8pO8SNp83XNdWG6tocBM1"
}
variable "ssh_private_key_file" {
  type    = string
  default = null
}

locals {
  output_folder       = "${path.root}/outputs/${uuidv4()}"
  share_mount_point   = "/mnt/${uuidv4()}"
  share_name          = uuidv4()
  ssh_authorized_keys = var.ssh_private_key_file == null ? [] : [file("${var.ssh_private_key_file}.pub")]
  username            = replace(uuidv4(), "-", "") # Username length limit is 32.
}

source "qemu" "image" {
  iso_checksum = var.iso_checksum
  iso_url      = "https://releases.ubuntu.com/${var.iso_version}/ubuntu-${var.iso_version}-desktop-amd64.iso"

  output_directory = local.output_folder
  # Required for cloud-init user data `write_files` to work.
  shutdown_command = "sudo shutdown now"

  cpus   = 2
  memory = 4096 # MiB.

  accelerator = "kvm"
  format      = "qcow2"

  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "20m"
  ssh_username         = local.username

  http_bind_address = "127.0.0.1"
  http_content = {
    "/meta-data" = ""
    "/user-data" = join("\n", ["#cloud-config", jsonencode({
      autoinstall = {
        version = 1
        identity = {
          hostname = uuidv4() # Field is required.
          password = var.password_hash
          username = local.username
        }
        keyboard = {
          layout  = "de"
          variant = "neo"
        }
        ssh = {
          authorized-keys = local.ssh_authorized_keys
          install-server  = true
        }
        user-data = {
          mounts = [
            [local.share_name, local.share_mount_point, "virtiofs"],
          ]
          users = [
            {
              name = local.username
              sudo = "ALL=(root) NOPASSWD: /usr/sbin/shutdown now"
            },
          ]
          write_files = [
            {
              content = jsonencode({
                policies = {
                  EnableTrackingProtection = {
                    Value = true
                  }
                  OfferToSaveLogins  = false
                  SanitizeOnShutdown = true
                }
              })
              path = "/etc/firefox/policies/policies.json"
            },
          ]
        }
      }
    })])
  }

  # Adapted from Bento (update-worthy,
  # https://github.com/chef/bento/blob/main/os_pkrvars/ubuntu/ubuntu-24.04-x86_64.pkrvars.hcl):
  boot_steps = [
    ["e<wait>", "Edit boot commands"],
    ["<down><down><down>", "Go to line `linux …`"],
    ["<end> autoinstall", "Use Ubuntu Autoinstall"],
    [" ds=nocloud", "Use cloud-init via NoCloud data source"],
    ["\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}", "Use Packer server"],
    ["<wait><f10>", "Boot now"],
  ]
}

build {
  sources = ["source.qemu.image"]

  post-processor "manifest" {
    custom_data = {
      iso_version   = var.iso_version
      output_folder = local.output_folder
      share_name    = local.share_name
    }
  }
}
