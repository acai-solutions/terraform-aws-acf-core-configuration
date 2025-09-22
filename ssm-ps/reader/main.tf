# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [
        aws.configuration_reader
      ]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CONFIGURATION READER
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ssm_parameters_by_path" "configuration" {
  path      = var.parameter_name_prefix
  recursive = true
  provider  = aws.configuration_reader
}

data "aws_ssm_parameter" "configuration" {
  for_each = toset(data.aws_ssm_parameters_by_path.configuration.names)
  name     = each.value
  provider = aws.configuration_reader
}

locals {
  flat_configuration = { for name, param in data.aws_ssm_parameter.configuration : name => param.value }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ UNFLATTEN
# ---------------------------------------------------------------------------------------------------------------------
module "simple_map_to_complex_map" {
  source = "../../shared/simple_map_to_complex_map"

  flat_configuration = local.flat_configuration
  prefix             = var.parameter_name_prefix
}

locals {
  unflattened_configuration = module.simple_map_to_complex_map.unflattened_configuration
}
