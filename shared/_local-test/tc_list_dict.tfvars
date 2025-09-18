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
  simple_string = "test_value"
  dict_list = [
    {
      name    = "dict1"
      value   = "value1"
      enabled = "true"
    },
    {
      name    = "dict2"
      value   = "value2"
      enabled = "false"
      nested = {
        sub_key = "sub_value"
      }
    }
  ]
  mixed_structure = {
    items = [
      {
        id   = "item1"
        tags = ["production", "critical"]
      },
      {
        id   = "item2"
        tags = ["development"]
        config = {
          timeout = "30"
          retry   = "true"
        }
      }
    ]
  }
}
prefix = "/test"
