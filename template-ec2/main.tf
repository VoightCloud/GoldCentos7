terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.4"
    }
  }
}


# resources, other modules, data filters
provider "proxmox" {
  pm_api_url      = "https://192.168.137.7:8006/api2/json"
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "gold_build" {

  count       = 1 # just want 1 for now, set to 0 and apply to destroy VM
  name        = "mercury-vm-${count.index + 1}"
  #count.index starts at 0, so + 1 means this VM will be named test-vm-1 in proxmox
  # this now reaches out to the vars file. I could've also used this var above in the pm_api_url setting but wanted to spell it out up there. target_node is different than api_url. target_node is which node hosts the template and thus also which node will host the new VM. it can be different than the host you use to communicate with the API. the variable contains the contents "prox-1u"
  target_node = var.proxmox_host
  clone       = var.template_name
  full_clone  = false

  vmid        = var.vmid
  # basic VM settings here. agent refers to guest agent
  agent       = 1
  bios        = "ovmf"
  os_type     = "cloud-init"
  cores       = 2
  sockets     = 1
  cpu         = "host"
  memory      = 2048

  scsihw      = "virtio-scsi-single"
  bootdisk    = "scsi0"
  disk {
    slot     = 0
    # set disk size here. leave it small for testing because expanding the disk takes time.
    size     = var.OSDiskSize
    type     = "scsi"
    storage  = "local"
    iothread = 1
  }

  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # the ${count.index + 1} thing appends text to the end of the ip address
  # in this case, since we are only adding a single VM, the IP will
  # be 10.98.1.91 since count.index starts at 0. this is how you can create
  # multiple VMs and have an IP assigned to each (.91, .92, .93, etc.)
  ipconfig0 = "ip=192.168.137.20${count.index + 1}/24,gw=192.168.137.1"

  # sshkeys set using variables. the variable contains the text of the key.
  sshkeys = <<EOF
  ${var.ssh_public_key}
  EOF
}

locals {
  hostname = "${var.number}${var.build_number}"
}

/* Null resource that generates a cloud-config file per vm */
data "template_file" "user_data" {
  count    = 1
  template = file("${path.module}/userdata.tmpl")
  vars     = {
    hostname = "vm-${count.index}"
    dna      = var.template_name
    #    pubkey   =  var.ssh_public_key # file("~/.ssh/id_rsa.pub")
    #    fqdn     = "vm-${count.index}.voight.org"
  }
}

resource "local_file" "cloud_init_user_data_file" {
  count    = 1
  content  = data.template_file.user_data[count.index].rendered
  filename = "${path.module}/user_data_${count.index}.cfg"
}

resource "null_resource" "cloud_init_config_files" {
  count = 1
  connection {
    type        = "ssh"
    user        = "ec2-admin"
    host        = "192.168.137.20${count.index + 1}"
    private_key = file("./ssh-key.pem")
  }

  provisioner "file" {
    source      = local_file.cloud_init_user_data_file[count.index].filename
    destination = "user_data_vm-${count.index}.sh"
  }

  provisioner "remote-exec" {
    connection {
      script_path = "/home/ec2-admin/run-userdata.sh"
    }
    inline = [
      "chmod +x /home/ec2-admin/user_data_vm-${count.index}.sh",
      "sudo /home/ec2-admin/user_data_vm-${count.index}.sh"
    ]
  }
}
