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
# ¦ IAM ROLES (writer + reader)
# ---------------------------------------------------------------------------------------------------------------------
# Bootstraps the cross-account IAM roles the writer and reader providers assume. Isolated here so each
# example's main.tf focuses on the input shape and the writer/reader wiring.
module "core_configuration_roles" {
  source = "../../ssm-ps/iam-roles"

  trusted_account_ids   = [var.account_ids.workload]
  parameter_name_prefix = local.parameter_name_prefix
  iam_roles = {
    configuration_reader_role_name = "acf-core-configuration-reader-role-test1"
    configuration_writer_role_name = "acf-core-configuration-writer-role-test1"
  }

  providers = {
    aws = aws.foundation
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDERS (writer + reader)
# ---------------------------------------------------------------------------------------------------------------------
# Writer / reader providers assume the IAM roles created above. Their ARNs are produced at apply time,
# so these provider blocks live next to the module they depend on.
provider "aws" {
  region = var.aws_region
  alias  = "configuration_writer"
  assume_role {
    role_arn = module.core_configuration_roles.configuration_writer_role_arn
  }
}

provider "aws" {
  region = var.aws_region
  alias  = "configuration_reader"
  assume_role {
    role_arn = module.core_configuration_roles.configuration_reader_role_arn
  }
}
