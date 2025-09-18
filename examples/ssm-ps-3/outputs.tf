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
  description = "Are local.configuration_add_on similar to the read configuration?"
  value = merge(
    local.configuration_add_on,
    local.configuration_add_on1,
    local.configuration_add_on2
  ) == module.core_configuration_reader.unflattened_configuration
}

output "core_configuration_reader" {
  description = "Read configuration"
  value       = module.core_configuration_reader.unflattened_configuration
}
