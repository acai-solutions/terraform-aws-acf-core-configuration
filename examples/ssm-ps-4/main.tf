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
# Stress-test the 15-pass flatten/unflatten ladder. The deepest leaf sits at level 15 and is accompanied
# by sibling values at intermediate levels plus a list (round-tripped via the default json strategy), so
# the round-trip exercises every pass of both shared/complex_map_to_simple_map and shared/simple_map_to_complex_map.
locals {
  parameter_name_prefix = "/test4"

  configuration_add_on = {
    l1 = {
      sibling_at_l1 = "value-l1"
      l2 = {
        sibling_at_l2 = "value-l2"
        l3 = {
          sibling_at_l3 = "value-l3"
          l4 = {
            sibling_at_l4 = "value-l4"
            l5 = {
              sibling_at_l5 = "value-l5"
              l6 = {
                sibling_at_l6 = "value-l6"
                l7 = {
                  sibling_at_l7 = "value-l7"
                  l8 = {
                    sibling_at_l8 = "value-l8"
                    l9 = {
                      sibling_at_l9 = "value-l9"
                      l10 = {
                        sibling_at_l10 = "value-l10"
                        l11 = {
                          sibling_at_l11 = "value-l11"
                          l12 = {
                            sibling_at_l12 = "value-l12"
                            l13 = {
                              sibling_at_l13 = "value-l13"
                              l14 = {
                                sibling_at_l14 = "value-l14"
                                l15 = {
                                  deepest_leaf  = "made it to depth 15"
                                  deepest_list  = ["a", "b", "c"]
                                  deepest_count = "3"
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
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
