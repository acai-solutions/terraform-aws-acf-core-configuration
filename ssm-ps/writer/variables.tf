# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


variable "configuration_writer_role_arn" {
  description = "ARN of the IAM role used for writing configuration."
  type        = string
}

variable "configuration_add_on" {
  description = "Complex map of configuration add-on."
  type        = any
  default     = {}
}

variable "configuration_add_on_list" {
  description = "List of complex maps for configuration add-ons."
  type        = any
  default     = []

  validation {
    condition     = can(length(var.configuration_add_on_list)) || can(var.configuration_add_on_list[0])
    error_message = "The configuration_add_on_list must be a list."
  }
}

variable "parameter_aws_region_name" {
  description = "AWS region name for the Parameter Store entries."
  type        = string
  default     = "eu-central-1"
}

variable "parameter_overwrite" {
  description = "Overwrite existing Parmeter Store entries."
  type        = bool
  default     = false
}

variable "parameter_name_prefix" {
  description = "Prefix the SSM Parameter Store entries shall have (to cluster them)."
  type        = string
  default     = "/foundation"
}

variable "kms_key_arn" {
  description = "KMS Key to be used to encrypt the SSM Parameter Store entries."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null ? true : can(regex("^arn:aws:kms", var.kms_key_arn))
    error_message = "Value must contain ARN, starting with \"arn:aws:kms\"."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ COMMON
# ---------------------------------------------------------------------------------------------------------------------
variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
