# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


variable "trusted_account_ids" {
  description = "Account IDs allowed to write Configuration Items. Will override provided org_id."
  type        = list(string)
  default     = ["*"]
}

variable "parameter_name_prefix" {
  description = "Prefix the SSM Parameter Store entries shall have (to cluster them)."
  type        = string
  default     = "/foundation"
}

variable "iam_roles" {
  type = object({
    configuration_reader_role_name = optional(string, "core-configuration-reader-role") # Name of IAM role which will be created to read Configuration Items from SSM Parameter Store.
    configuration_writer_role_name = optional(string, "core-configuration-writer-role") # Name of IAM role which will be created to write Configuration Items into SSM Parameter Store.
    role_path                      = optional(string, null)
    permissions_boundary_arn       = optional(string, null) # ARN of the policy that is used to set the permissions boundary for all IAM roles of the module.
    store_role_arns                = optional(bool, false)  # Specifies, if the Core Configuration IAM Role-ARNs shall be sored to the SSM Parameter Store.
  })
  default = {
    configuration_reader_role_name = "core-configuration-reader-role"
    configuration_writer_role_name = "core-configuration-writer-role"
    role_path                      = null
    permissions_boundary_arn       = null
    store_role_arns                = false
  }

  validation {
    condition     = var.iam_roles.role_path == null ? true : can(regex("^\\/", var.iam_roles.role_path))
    error_message = "IAM Role Path must start with '/'."
  }

  validation {
    condition     = var.iam_roles.permissions_boundary_arn == null ? true : can(regex("^arn:aws:iam", var.iam_roles.permissions_boundary_arn))
    error_message = "Value must contain ARN, starting with 'arn:aws:iam'."
  }
}

variable "kms_key_arn" {
  description = "Arn of an existing KMS Key to be used to encrypt the Configuration Item entries."
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

