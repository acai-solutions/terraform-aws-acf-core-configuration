# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


variable "configuration_add_on" {
  description = "Complex map of configuration add-on."
  type        = any
}

variable "prefix" {
  description = "Prefix to the configuration-item keys."
  type        = string
  default     = "/foundation"
}