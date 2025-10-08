output "ipv4_addresses" {
  value = lxd_instance.landscape.ipv4_address
}

output "status" {
  value = lxd_instance.landscape.status
}


output "execs_output" {
  value     = lxd_instance.landscape.execs
  sensitive = true
}
