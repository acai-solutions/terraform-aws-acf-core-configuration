# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


variable "configuration_reader_role_arn" {
  description = "ARN of the IAM role used for reading configuration."
  type        = string
}

variable "parameter_aws_region_name" {
  description = "AWS region name for the Parameter Store entries."
  type        = string
  default     = "eu-central-1"
}

variable "parameter_name_prefix" {
  description = "Prefix the SSM Parameter Store entries shall have (to cluster them)."
  type        = string
  default     = "/foundation"
}