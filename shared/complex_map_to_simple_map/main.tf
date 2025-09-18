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
}

data "external" "flatten_configuration_add_on" {
  program = ["python", "${path.module}/python/flatten_map.py", jsonencode(var.configuration_add_on), var.prefix]
}

locals {
  flattened_configuration_add_on = jsondecode(data.external.flatten_configuration_add_on.result["result"])
}
