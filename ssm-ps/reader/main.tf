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
# ¦ CONFIGURATION READER
# ---------------------------------------------------------------------------------------------------------------------
data "external" "read_configuration" {
  program = ["python3", "${path.module}/python/read_from_ssm.py"]

  query = {
    parameter_name_prefix = var.parameter_name_prefix
    role_arn              = var.configuration_reader_role_arn
    aws_region            = var.parameter_aws_region_name
  }
}

locals {
  flat_configuration = data.external.read_configuration.result
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ UNFLATTEN
# ---------------------------------------------------------------------------------------------------------------------
module "simple_map_to_complex_map" {
  source = "../../shared/simple_map_to_complex_map"

  flat_configuration = local.flat_configuration
  prefix             = var.parameter_name_prefix
}

locals {
  unflattened_configuration = module.simple_map_to_complex_map.unflattened_configuration
}
