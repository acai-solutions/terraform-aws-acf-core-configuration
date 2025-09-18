# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


output "configuration_add_on" {
  description = "Provided complex map of configuration add-on."
  value       = var.configuration_add_on
}

output "flattened_configuration_add_on" {
  description = "Flattened configuration add-on."
  value       = local.flattened_configuration_add_on
}

output "unflattened_configuration_add_on" {
  description = "Unflattened configuration add-on."
  value       = local.unflattened_configuration_add_on
}

output "flattened_configuration_add_on2" {
  description = "Flattened configuration add-on."
  value       = local.flattened_configuration_add_on2
}

output "unflattened_configuration_add_on2" {
  description = "Unflattened configuration add-on."
  value       = local.unflattened_configuration_add_on2
}

output "similar" {
  description = "Is the unflattened_configuration_add_on similar to the provided var.configuration_add_on?"
  value       = var.configuration_add_on == local.unflattened_configuration_add_on && local.unflattened_configuration_add_on2 == local.unflattened_configuration_add_on
}

# Additional outputs for detailed testing
output "test_results" {
  description = "Detailed test results for different data types"
  value = {
    original_input               = var.configuration_add_on
    after_flatten_unflatten      = local.unflattened_configuration_add_on
    double_conversion            = local.unflattened_configuration_add_on2
    conversion_successful        = var.configuration_add_on == local.unflattened_configuration_add_on
    double_conversion_successful = local.unflattened_configuration_add_on2 == local.unflattened_configuration_add_on
    overall_success              = var.configuration_add_on == local.unflattened_configuration_add_on && local.unflattened_configuration_add_on2 == local.unflattened_configuration_add_on
  }
}

# Specific tests for list handling
output "list_handling_test" {
  description = "Test results specifically for list handling"
  value = {
    # Direct list detection at root level
    root_level_lists = [
      for k, v in var.configuration_add_on : k
      if can(length(v)) && !can(tostring(v))
    ]

    # String list detection at root level  
    root_level_string_lists = [
      for k, v in var.configuration_add_on : k
      if can(length(v)) && !can(tostring(v)) && can(v[0]) && can(tostring(v[0]))
    ]

    # Object list detection at root level
    root_level_object_lists = [
      for k, v in var.configuration_add_on : k
      if can(length(v)) && !can(tostring(v)) && can(v[0]) && can(keys(v[0]))
    ]

    # Nested structure analysis
    nested_objects = [
      for k, v in var.configuration_add_on : k
      if can(keys(v))
    ]

    # Count total structures
    total_lists = length([
      for k, v in var.configuration_add_on : k
      if can(length(v)) && !can(tostring(v))
    ])

    total_objects = length([
      for k, v in var.configuration_add_on : k
      if can(keys(v))
    ])

    # Structure summary
    structure_summary = {
      for k, v in var.configuration_add_on : k => {
        type        = can(keys(v)) ? "object" : can(length(v)) && !can(tostring(v)) ? "list" : "primitive"
        is_list     = can(length(v)) && !can(tostring(v))
        is_object   = can(keys(v))
        is_string   = can(tostring(v)) && !can(keys(v)) && !can(length(v))
        list_length = can(length(v)) && !can(tostring(v)) ? length(v) : null
        object_keys = can(keys(v)) ? keys(v) : null
      }
    }
  }
}