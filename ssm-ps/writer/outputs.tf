output "flattened_configuration_add_on" {
  description = "Flattened map of configuratio items which was stored in SSM Parameter Store."
  value       = local.flattened_configuration_add_on
}
