output "unflattened_configuration" {
  description = "Nested HCL object reconstructed from the flat input map."
  value       = local.unflattened_configuration
}
