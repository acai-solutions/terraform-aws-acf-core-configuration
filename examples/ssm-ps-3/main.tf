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
# Realistic configuration tree containing lists of objects (database connections) and lists of strings
# (service names). With list_strategy = "json" both round-trip back to real HCL collections.
locals {
  parameter_name_prefix = "/test3"

  configuration_add_on = {
    database = {
      connections = [
        {
          name = "primary"
          host = "db1.example.com"
          port = "5432"
          settings = {
            max_connections = "100"
            timeout         = "30"
          }
          tags = ["production", "primary"]
        },
        {
          name = "secondary"
          host = "db2.example.com"
          port = "5432"
          settings = {
            max_connections = "50"
            timeout         = "15"
            backup_enabled  = "true"
          }
          tags = ["production", "backup"]
        },
      ]
    }
    application = {
      services = ["api", "worker", "scheduler"]
      environments = [
        {
          name     = "prod"
          replicas = "3"
          resources = {
            cpu    = "2"
            memory = "4Gi"
          }
        },
        {
          name     = "staging"
          replicas = "1"
          resources = {
            cpu    = "1"
            memory = "2Gi"
          }
        },
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
