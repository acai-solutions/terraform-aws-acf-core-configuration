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
  string_list = [
    "item1",
    "item2",
    "item3"
  ]
  nested_object = {
    name = "test_nested"
    tags = [
      "tag1",
      "tag2"
    ]
  }
}
prefix = "/test"