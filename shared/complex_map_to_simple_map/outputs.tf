output "flattened_configuration_add_on" {
  description = "Flat map<string,string>: hierarchical key path => stringified leaf value."
  value       = local.flattened_configuration_add_on
}
