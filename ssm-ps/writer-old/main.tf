# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [
        aws.configuration_writer
      ]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  resource_tags = merge(
    var.resource_tags,
    {
      "module_provider" = "ACAI GmbH",
      "module_name"     = "terraform-aws-acf-core-configuration",
      "module_source"   = "github.com/acai-consulting/terraform-aws-acf-core-configuration",
      "module_version"  = /*inject_version_start*/ "1.4.1" /*inject_version_end*/
    }
  )
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA TRANSFORMATION
# ---------------------------------------------------------------------------------------------------------------------
module "complex_map_to_simple_map" {
  source = "../../shared/complex_map_to_simple_map"

  configuration_add_on = var.configuration_add_on
  prefix               = var.parameter_name_prefix
}

module "complex_maps_to_simple_maps" {
  source   = "../../shared/complex_map_to_simple_map"
  for_each = { for idx, val in var.configuration_add_on_list : idx => val } # Correct iteration over list with indexing

  configuration_add_on = each.value
  prefix               = var.parameter_name_prefix
}

locals {
  flattened_configuration_add_on = merge(
    module.complex_map_to_simple_map.flattened_configuration_add_on,
    merge([for instance in values(module.complex_maps_to_simple_maps) : instance.flattened_configuration_add_on]...)
  )
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ STORE CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
# Resource to use when NOT overwriting parameters (ignore changes)
resource "aws_ssm_parameter" "ssm_parameters_ignore" {
  for_each = var.parameter_overwrite ? {} : local.flattened_configuration_add_on

  name = each.key
  type = var.kms_key_arn == null ? "String" : "SecureString"
  # in case of encryption: 
  # The unencrypted value of a SecureString will be stored in the raw state as plain-text. 
  # Read more about sensitive data in state: https://developer.hashicorp.com/terraform/language/state/sensitive-data
  value    = each.value
  tags     = local.resource_tags
  key_id   = var.kms_key_arn
  provider = aws.configuration_writer

  lifecycle {
    ignore_changes = [value, tags]
  }
  depends_on = [module.complex_map_to_simple_map]
}

# Resource to use when overwriting parameters (do not ignore changes)
resource "aws_ssm_parameter" "ssm_parameters_overwrite" {
  for_each = var.parameter_overwrite ? local.flattened_configuration_add_on : {}

  name = each.key
  type = var.kms_key_arn == null ? "String" : "SecureString"
  # in case of encryption: 
  # The unencrypted value of a SecureString will be stored in the raw state as plain-text. 
  # Read more about sensitive data in state: https://developer.hashicorp.com/terraform/language/state/sensitive-data
  value      = each.value
  tags       = local.resource_tags
  key_id     = var.kms_key_arn
  overwrite  = true # currently seems to default to false. Will be removed after terraform aws 6.x
  provider   = aws.configuration_writer
  depends_on = [module.complex_map_to_simple_map]
}
