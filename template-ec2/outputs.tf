output "ip" {
  # value = "192.168.137.201"
  value = proxmox_vm_qemu.gold_build[proxmox_vm_qemu.gold_build.count.index].ipconfig0
}

output "vm_id" {
  value = "109"
}
#
#output "hostname" {
#  value = local.hostname
#}
#
#output "id" {
#  value = proxmox_vm_qemu.test_server.id
#}
#
