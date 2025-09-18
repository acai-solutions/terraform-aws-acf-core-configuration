# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


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

prefix = "/test"