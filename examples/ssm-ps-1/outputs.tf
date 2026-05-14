# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
#
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


output "test_success" {
  description = "Round-trip: reader's unflattened map equals the original input (canonical-JSON compare)."
  value       = jsonencode(module.core_configuration_reader.unflattened_configuration) == jsonencode(local.configuration_add_on)
}

output "core_configuration_reader" {
  description = "Read-back configuration (debugging aid)."
  value       = module.core_configuration_reader.unflattened_configuration
}
