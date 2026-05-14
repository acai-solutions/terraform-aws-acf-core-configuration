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
# Mixed scalars + simple lists + nested objects. Smallest example -- doubles as a smoke test.
locals {
  parameter_name_prefix = "/test1"

  configuration_add_on = {
    simple_string = "test_value"
    string_list = [
      "item1",
      "item2",
      "item3",
    ]
    nested_object = {
      name = "test_nested"
      tags = [
        "tag1",
        "tag2",
      ]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MODULES
# ---------------------------------------------------------------------------------------------------------------------
module "core_configuration_writer" {
  source = "../../ssm-ps/writer"

  configuration_add_on  = local.configuration_add_on
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
