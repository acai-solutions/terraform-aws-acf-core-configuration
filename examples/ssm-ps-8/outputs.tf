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
  description = "Is aws_iam_role.example.arn similar to the read configuration?"
  value = (module.core_configuration_reader.unflattened_configuration.iam_role_arn1 == aws_iam_role.example1.arn &&
  module.core_configuration_reader.unflattened_configuration.iam_role_arn2 == aws_iam_role.example2.arn)

}

output "core_configuration_reader" {
  description = "Read configuration"
  value       = module.core_configuration_reader.unflattened_configuration
}
