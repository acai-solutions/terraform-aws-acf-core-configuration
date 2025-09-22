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
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
  # please use the target role you need.
  # create additional providers in case your module provisions to multiple core accounts.
  assume_role {
    role_arn = "arn:aws:iam::471112796356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Org-Mgmt Account
    #role_arn = "arn:aws:iam::590183833356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Logging Account
    #role_arn = "arn:aws:iam::992382728088:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Security Account
    #role_arn = "arn:aws:iam::767398146370:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Workload Account
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ BACKEND
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "remote" {
    organization = "acai"
    hostname     = "app.terraform.io"

    workspaces {
      name = "aws-testbed"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ VERSIONS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = []
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
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
        }
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
        }
      ]
    }
  }

  parameter_name_prefix = "/test5"

}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MODULES
# ---------------------------------------------------------------------------------------------------------------------
module "core_configuration_roles" {
  source = "../../ssm-ps/iam-roles"

  trusted_account_ids   = [data.aws_caller_identity.current.account_id]
  parameter_name_prefix = local.parameter_name_prefix
  iam_roles = {
    configuration_reader_role_name = "test-reader"
    configuration_writer_role_name = "test-writer"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE CONFIGURATION - WRITER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
  alias  = "core_configuration_writer"
  assume_role {
    role_arn = module.core_configuration_roles.configuration_writer_role_arn
  }
}

module "core_configuration_writer" {
  source = "../../ssm-ps/writer"

  configuration_add_on  = local.configuration_add_on
  parameter_overwrite   = true
  parameter_name_prefix = local.parameter_name_prefix
  providers = {
    aws.configuration_writer = aws.core_configuration_writer
  }
  depends_on = [
    module.core_configuration_roles
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE CONFIGURATION - READER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
  alias  = "core_configuration_reader"
  assume_role {
    role_arn = module.core_configuration_roles.configuration_reader_role_arn
  }
}

module "core_configuration_reader" {
  source = "../../ssm-ps/reader"

  parameter_name_prefix = local.parameter_name_prefix
  providers = {
    aws.configuration_reader = aws.core_configuration_reader
  }
  depends_on = [
    module.core_configuration_roles,
    module.core_configuration_writer
  ]
}

