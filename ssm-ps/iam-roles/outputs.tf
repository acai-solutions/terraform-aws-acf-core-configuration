# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


output "configuration_writer_role_name" {
  description = "Name of role used to write configuration into SSM Parameter Store."
  value       = aws_iam_role.configuration_writer.name
}

output "configuration_writer_role_arn" {
  description = "ARN of role used to write configuration into SSM Parameter Store."
  value       = aws_iam_role.configuration_writer.arn
}

output "configuration_reader_role_name" {
  description = "Name of role used to read configuration into SSM Parameter Store."
  value       = aws_iam_role.configuration_reader.name
}

output "configuration_reader_role_arn" {
  description = "ARN of role used to read configuration into SSM Parameter Store."
  value       = aws_iam_role.configuration_reader.arn
}
