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
  assume_role {
    role_arn = "arn:aws:iam::471112796356:role/OrganizationAccountAccessRole"
  }
  #profile = "471112796356_AdministratorAccess"
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
  parameter_name_prefix = "/test8"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROBE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "example1" {
  name = "example-iam-role1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role" "example2" {
  name = "example-iam-role2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
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
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  configuration_add_on1 = {
    iam_role_arn1 = aws_iam_role.example1.arn
  }
  configuration_add_on2 = {

    iam_role_arn2 = aws_iam_role.example2.arn
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE CONFIGURATION - WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "core_configuration_writer1" {
  source = "../../ssm-ps/writer"

  configuration_writer_role_arn = module.core_configuration_roles.configuration_writer_role_arn
  configuration_add_on          = local.configuration_add_on1
  parameter_overwrite           = true
  parameter_name_prefix         = local.parameter_name_prefix
  depends_on = [
    module.core_configuration_roles
  ]
}

module "core_configuration_writer2" {
  source = "../../ssm-ps/writer"

  configuration_writer_role_arn = module.core_configuration_roles.configuration_writer_role_arn
  configuration_add_on          = local.configuration_add_on2
  parameter_overwrite           = true
  parameter_name_prefix         = local.parameter_name_prefix
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

  configuration_reader_role_arn = module.core_configuration_roles.configuration_reader_role_arn
  parameter_name_prefix         = local.parameter_name_prefix

  depends_on = [
    module.core_configuration_roles,
    module.core_configuration_writer1,
    module.core_configuration_writer2
  ]
}
