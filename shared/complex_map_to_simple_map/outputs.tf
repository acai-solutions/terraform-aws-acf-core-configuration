output "configuration_add_on" {
  description = "The map of configuration items which are stored as a map in SSM Parameter Store."
  value       = var.configuration_add_on
}

output "flattened_configuration_add_on" {
  description = "The map of configuration items which are stored as a map in SSM Parameter Store."
  value       = local.flattened_configuration_add_on
}
