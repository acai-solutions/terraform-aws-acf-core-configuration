# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


output "flat_configuration" {
  description = "Flat configuration-map."
  value       = var.flat_configuration
}

output "unflattened_configuration" {
  description = "Unflattened configuration-map."
  value       = local.unflattened_configuration
}
