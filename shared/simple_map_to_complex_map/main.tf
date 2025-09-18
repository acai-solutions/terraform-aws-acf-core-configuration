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

data "external" "unflatten_configuration" {
  program = [
    "python",
    "${path.module}/python/unflatten_map.py",
    jsonencode(var.flat_configuration),
    var.prefix,
    "--wrap-external"
  ]
}

locals {
  # Nested structure produced by unflatten_map.py
  unflattened_configuration = jsondecode(data.external.unflatten_configuration.result["result"])
}