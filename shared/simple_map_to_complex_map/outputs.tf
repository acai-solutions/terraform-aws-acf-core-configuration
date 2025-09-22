output "flat_configuration" {
  description = "Flat configuration-map."
  value       = var.flat_configuration
}

output "unflattened_configuration" {
  description = "Unflattened configuration-map."
  value       = local.unflattened_configuration
}
