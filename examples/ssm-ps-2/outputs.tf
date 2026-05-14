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
  description = "Round-trip: merge of all three add-ons equals the reader output."
  value = jsonencode(merge(
    local.configuration_add_on,
    local.configuration_add_on1,
    local.configuration_add_on2,
  )) == jsonencode(module.core_configuration_reader.unflattened_configuration)
}

output "core_configuration_reader" {
  description = "Read-back configuration (debugging aid)."
  value       = module.core_configuration_reader.unflattened_configuration
}
