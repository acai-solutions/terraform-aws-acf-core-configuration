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
# ¦ VERSIONS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ INPUT
# ---------------------------------------------------------------------------------------------------------------------
# Combined: the writer takes both `configuration_add_on` AND `configuration_add_on_list` and flattens
# every entry under the same prefix.
locals {
  parameter_name_prefix = "/test2"

  configuration_add_on = {
    l1_e1_item = "value l1_e1_item"
    l1_e2_item = "value l1_e3_item"
    l1_e3_node = {
      l1_e3_l2_e1_item = "value l1_e3_l2_e1_item"
      l1_e3_l2_e2_node = {
        l1_e3_l2_e2_l3_e1_item = "value l1_e3_l2_e2_l3_e1_item"
        l1_e3_l2_e2_l3_e2_item = "value l1_e3_l2_e2_l3_e2_item"
      }
    }
  }
  configuration_add_on1 = {
    addon1_l1_e1_item = "value addon1_l1_e1_item"
    addon1_l1_e2_item = "value addon1_l1_e3_item"
    addon1_l1_e3_node = {
      addon1_l1_e3_l2_e1_item = "value addon1_l1_e3_l2_e1_item"
      addon1_l1_e3_l2_e2_node = {
        addon1_l1_e3_l2_e2_l3_e1_item = "value addon1_l1_e3_l2_e2_l3_e1_item"
        addon1_l1_e3_l2_e2_l3_e2_item = "value addon1_l1_e3_l2_e2_l3_e2_item"
      }
    }
  }
  configuration_add_on2 = {
    addon2_l1_e1_item = "value addon2_l1_e1_item"
    addon2_l1_e2_item = "value addon2_l1_e3_item"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MODULES
# ---------------------------------------------------------------------------------------------------------------------
module "core_configuration_writer" {
  source = "../../ssm-ps/writer"

  configuration_add_on = local.configuration_add_on
  configuration_add_on_list = [
    local.configuration_add_on1,
    local.configuration_add_on2,
  ]
  parameter_overwrite   = true
  parameter_name_prefix = local.parameter_name_prefix

  providers = {
    aws.configuration_writer = aws.configuration_writer
  }

  depends_on = [module.core_configuration_roles]
}

module "core_configuration_reader" {
  source = "../../ssm-ps/reader"

  parameter_name_prefix = local.parameter_name_prefix

  providers = {
    aws.configuration_reader = aws.configuration_reader
  }

  depends_on = [
    module.core_configuration_roles,
    module.core_configuration_writer,
  ]
}
