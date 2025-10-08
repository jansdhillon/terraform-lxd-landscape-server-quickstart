output "ipv4_addresses" {
  value = module.landscape_server_quickstart.ipv4_addresses
}

output "status" {
  value = module.landscape_server_quickstart.status
}


output "execs_output" {
  value     = module.landscape_server_quickstart.execs_output
  sensitive = true
}
