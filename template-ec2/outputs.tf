output "ip" {
  # value = "192.168.137.201"
  value = proxmox_vm_qemu.gold_build[0].ipconfig0
}

output "vm_id" {
  value = proxmox_vm_qemu.gold_build[0].vm_id
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
