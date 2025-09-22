# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
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
data "aws_caller_identity" "this_account" {}
data "aws_organizations_organization" "this_org" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  org_id = data.aws_organizations_organization.this_org.id
  resource_tags = merge(
    var.resource_tags,
    {
      "module_provider" = "ACAI GmbH",
      "module_name"     = "terraform-aws-acf-core-configuration",
      "module_source"   = "github.com/acai-consulting/terraform-aws-acf-core-configuration",
      "module_version"  = /*inject_version_start*/ "1.3.3" /*inject_version_end*/
    }
  )
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ ROLE TRUST POLICY
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "trust_policy" {
  statement {
    sid    = "TrustPolicy"
    effect = "Allow"

    principals {
      identifiers = var.trusted_account_ids
      type        = "AWS"
    }
    actions = [
      "sts:AssumeRole"
    ]
    dynamic "condition" {
      for_each = var.trusted_account_ids == ["*"] ? ["true"] : []
      content {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [local.org_id]
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CONFIGURATION READER - IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
# IAM Role that can be assumed by anyone in the organization
# to query ssm parameter store.
resource "aws_iam_role" "configuration_reader" {
  name                 = var.iam_roles.configuration_reader_role_name
  assume_role_policy   = data.aws_iam_policy_document.trust_policy.json
  path                 = var.iam_roles.role_path
  permissions_boundary = var.iam_roles.permissions_boundary_arn
  tags                 = local.resource_tags
}

resource "aws_iam_role_policy" "configuration_reader" {
  name       = replace(aws_iam_role.configuration_reader.name, "role", "policy")
  role       = aws_iam_role.configuration_reader.name
  policy     = data.aws_iam_policy_document.configuration_reader.json
  depends_on = [aws_iam_role.configuration_reader]
}

# need a wildcard for "ssm:GetParametersByPath", "ssm:DescribeParameters"
#tfsec:ignore:AVD-AWS-0057
data "aws_iam_policy_document" "configuration_reader" {
  statement {
    sid    = "AllowSSMForListContext1"
    effect = "Allow"
    actions = [
      "ssm:GetParameterHistory",
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:DescribeParameters"
    ]
    resources = [
      replace("arn:aws:ssm:*:${data.aws_caller_identity.this_account.account_id}:parameter/${var.parameter_name_prefix}/*", "////", "/"),
    ]
  }
  statement {
    sid    = "AllowSSMForListContext2"
    effect = "Allow"
    actions = [
      "ssm:GetParametersByPath"
    ]
    resources = [
      replace("arn:aws:ssm:*:${data.aws_caller_identity.this_account.account_id}:parameter/${var.parameter_name_prefix}", "////", "/")
    ]
  }
  dynamic "statement" {
    for_each = var.kms_key_arn != null ? ["enabled"] : []
    content {
      sid    = "AllowKmsCmkAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt"
      ]
      resources = [var.kms_key_arn]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CONFIGURATION WRITER - IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
# IAM role that can be assumed by anyone in the organization
# to write Configuration Items to the SSM Parameter Store
resource "aws_iam_role" "configuration_writer" {
  name                 = var.iam_roles.configuration_writer_role_name
  assume_role_policy   = data.aws_iam_policy_document.trust_policy.json
  path                 = var.iam_roles.role_path
  permissions_boundary = var.iam_roles.permissions_boundary_arn
  tags                 = local.resource_tags
}

resource "aws_iam_role_policy" "configuration_writer" {
  name   = replace(aws_iam_role.configuration_writer.name, "role", "policy")
  role   = aws_iam_role.configuration_writer.name
  policy = data.aws_iam_policy_document.configuration_writer.json
}

# need a wildcard for "ssm:GetParametersByPath", "ssm:DescribeParameters"
#tfsec:ignore:AVD-AWS-0057
data "aws_iam_policy_document" "configuration_writer" {
  statement {
    sid    = "AllowSSM"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:DeleteParameter",
      "ssm:DeleteParameters",
      "ssm:PutParameter",
      "ssm:AddTagsToResource",
      "ssm:RemoveTagsFromResource",
      "ssm:ListTagsForResource"
    ]
    resources = [
      replace("arn:aws:ssm:*:${data.aws_caller_identity.this_account.account_id}:parameter/${var.parameter_name_prefix}/*", "////", "/"),
    ]
  }
  statement {
    sid    = "AllowSSMForListContext2"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.this_account.account_id}:*"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ STORE PRINCIPAL ARNS - OPTIONAL 
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "reader_role_arn" {
  count = var.iam_roles.store_role_arns == true ? 1 : 0

  name = "${var.parameter_name_prefix}/governance/core_configuration/reader_role_arn"
  type = var.kms_key_arn == null ? "String" : "SecureString"
  # in case of encryption: 
  # The unencrypted value of a SecureString will be stored in the raw state as plain-text. 
  # Read more about sensitive data in state: https://developer.hashicorp.com/terraform/language/state/sensitive-data
  value  = aws_iam_role.configuration_reader.arn
  key_id = var.kms_key_arn
  tags   = local.resource_tags
}

resource "aws_ssm_parameter" "writer_role_arn" {
  count = var.iam_roles.store_role_arns == true ? 1 : 0

  name = "${var.parameter_name_prefix}/governance/core_configuration/writer_role_arn"
  type = var.kms_key_arn == null ? "String" : "SecureString"
  # in case of encryption: 
  # The unencrypted value of a SecureString will be stored in the raw state as plain-text. 
  # Read more about sensitive data in state: https://developer.hashicorp.com/terraform/language/state/sensitive-data
  value  = aws_iam_role.configuration_writer.arn
  key_id = var.kms_key_arn
  tags   = local.resource_tags
}
