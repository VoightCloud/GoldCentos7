# application-specific configuration

variable "proxmox_host" {
  description = "Which host to run image"
  default = "ugli"
}

#Most recent AMI to search for
variable "template_name" {
  description = "The name of the instance to clone"
  default = "copper-centos7-1640446036"
}

#OS Disk Size. Minimum size is 48GB.
variable "OSDiskSize" {
  description = "Operating System Drive Size. Minimum 48GB."
  default = "48G"
}

variable "number" {
  description = "hostname number incrementer"
  default = "2"
}

variable "build_number" {
  description = "build number to append to autoincrementer"
  default = "1"
}

variable "ssh_public_key" {
  description = "The SSH to use to connect to the system."
}

variable "fullscap" {
  description = "Whether to run OpenSCAP Before and After scans or just the After"
  default = true
}

