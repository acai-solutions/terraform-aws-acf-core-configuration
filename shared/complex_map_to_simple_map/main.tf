# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"
}

data "external" "flatten_configuration_add_on" {
  program = [var.python_name, "${path.module}/python/flatten_map.py", jsonencode(var.configuration_add_on), var.prefix]
}

locals {
  flattened_configuration_add_on = jsondecode(data.external.flatten_configuration_add_on.result["result"])
}
