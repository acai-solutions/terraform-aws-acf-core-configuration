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
# ¦ PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------
# The Foundation Configuration Account hosts the SSM Parameter Store. For these examples we use the
# workload account as the Foundation account so each example is self-contained.
provider "aws" {
  region = var.aws_region
  alias  = "foundation"
  assume_role {
    role_arn = "arn:${var.aws_partition}:iam::${var.account_ids.workload}:role/${var.iam_role_name}"
  }
}
