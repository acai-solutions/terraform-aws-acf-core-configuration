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

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
resource "random_id" "cluster_id" {
  byte_length = 8 # creates 16 hex characters
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  resource_tags = merge(
    var.resource_tags,
    {
      "module_provider"             = "ACAI GmbH",
      "module_parameter_cluster_id" = random_id.cluster_id.hex
      "module_name"                 = "terraform-aws-acf-core-configuration",
      "module_source"               = "github.com/acai-consulting/terraform-aws-acf-core-configuration",
      "module_version"              = /*inject_version_start*/ "1.4.1" /*inject_version_end*/
    }
  )
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA TRANSFORMATION
# ---------------------------------------------------------------------------------------------------------------------
module "complex_map_to_simple_map" {
  source = "../../shared/complex_map_to_simple_map"

  configuration_add_on = var.configuration_add_on
  prefix               = var.parameter_name_prefix
}

module "complex_maps_to_simple_maps" {
  source   = "../../shared/complex_map_to_simple_map"
  for_each = { for idx, val in var.configuration_add_on_list : idx => val } # Correct iteration over list with indexing

  configuration_add_on = each.value
  prefix               = var.parameter_name_prefix
}

locals {
  flattened_configuration_add_on = merge(
    module.complex_map_to_simple_map.flattened_configuration_add_on,
    merge([for instance in values(module.complex_maps_to_simple_maps) : instance.flattened_configuration_add_on]...)
  )
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ STORE CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
# Resource to use when NOT overwriting parameters (ignore changes)
locals {
  is_windows = dirname("/") == "\\"

  map_b64  = base64encode(jsonencode(local.flattened_configuration_add_on))
  tags_b64 = base64encode(jsonencode(local.resource_tags))

  base_args_windows = "--parameter_name_prefix \"${var.parameter_name_prefix}\" --map-base64 \"${local.map_b64}\" --tags-base64 \"${local.tags_b64}\" --parameter_overwrite \"${var.parameter_overwrite}\" --cluster-id \"${random_id.cluster_id.hex}\" --role-arn \"${var.configuration_writer_role_arn}\" ${var.kms_key_arn != null ? "--kms-key-id \"${var.kms_key_arn}\"" : ""}"

  base_args_unix = "--parameter_name_prefix '${var.parameter_name_prefix}' --map-base64 '${local.map_b64}' --tags-base64 '${local.tags_b64}' --parameter_overwrite '${var.parameter_overwrite}' --cluster-id '${random_id.cluster_id.hex}' --role-arn '${var.configuration_writer_role_arn}' ${var.kms_key_arn != null ? "--kms-key-id '${var.kms_key_arn}'" : ""}"

  windows_command = "python ${replace(path.module, "/", "\\")}\\python\\write_to_ssm.py ${local.base_args_windows}"
  unix_command    = "python3 ${path.module}/python/write_to_ssm.py ${local.base_args_unix}"
}

resource "null_resource" "write_flattened_map_to_ssm" {
  triggers = {
    map_content  = local.map_b64
    tags_content = local.tags_b64
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : ["/bin/bash", "-c"]
    command     = local.is_windows ? local.windows_command : local.unix_command
    environment = {
      AWS_DEFAULT_REGION = var.parameter_aws_region_name
    }
  }
}

locals {
  cleanup_base_args = "--parameter_name_prefix '${var.parameter_name_prefix}' --cluster-id '${random_id.cluster_id.hex}' --role-arn '${var.configuration_writer_role_arn}'"

  cleanup_windows_command = "python ${replace(path.module, "/", "\\")}\\python\\remove_from_ssm.py ${local.cleanup_base_args}"
  cleanup_unix_command    = "python3 ${path.module}/python/remove_from_ssm.py ${local.cleanup_base_args}"
}

resource "null_resource" "cleanup_ssm" {
  triggers = {
    parameter_name_prefix = var.parameter_name_prefix
    cluster_id            = random_id.cluster_id.hex
    role_arn              = var.configuration_writer_role_arn
    # Better OS detection stored in triggers
    is_windows  = local.is_windows
    script_path = "${path.module}/python/remove_from_ssm.py"
    # Store both command variations in triggers
    windows_script_path = replace("${path.module}/python/remove_from_ssm.py", "/", "\\")
    aws_region          = var.parameter_aws_region_name
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = self.triggers.is_windows == "true" ? ["PowerShell", "-Command"] : ["/bin/bash", "-c"]
    command = self.triggers.is_windows == "true" ? (
      "python \"${self.triggers.windows_script_path}\" --parameter_name_prefix \"${self.triggers.parameter_name_prefix}\" --cluster-id \"${self.triggers.cluster_id}\" --role-arn \"${self.triggers.role_arn}\""
      ) : (
      "python3 '${self.triggers.script_path}' --parameter_name_prefix '${self.triggers.parameter_name_prefix}' --cluster-id '${self.triggers.cluster_id}' --role-arn '${self.triggers.role_arn}'"
    )
    environment = {
      AWS_DEFAULT_REGION = self.triggers.aws_region
    }
  }
}