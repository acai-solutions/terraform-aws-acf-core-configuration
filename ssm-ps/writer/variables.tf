variable "configuration_add_on" {
  description = "Complex map of configuration add-on."
  type        = any
  default     = {}
}

variable "configuration_add_on_list" {
  description = "List of complex maps for configuration add-ons."
  type        = any
  default     = []

  validation {
    condition     = can(length(var.configuration_add_on_list)) || can(var.configuration_add_on_list[0])
    error_message = "The configuration_add_on_list must be a list."
  }
}

variable "parameter_overwrite" {
  description = "Overwrite existing Parmeter Store entries."
  type        = bool
  default     = false
}

variable "parameter_name_prefix" {
  description = "Prefix the SSM Parameter Store entries shall have (to cluster them)."
  type        = string
  default     = "/foundation"
}

variable "list_strategy" {
  description = <<-EOT
    How list values inside `configuration_add_on` are stored:
      * "json"    => the whole list is stored as a single JSON-encoded SSM parameter under the parent key.
                     Recommended default: makes the reader's unflatten round-trip into real HCL lists
                     (jsondecode is applied to every leaf).
      * "indexed" => one SSM parameter per element, key suffixed with the numeric index ("key/0", "key/1", ...).
                     The reader will return numeric-keyed maps for these branches, NOT lists.
  EOT
  type        = string
  default     = "json"

  validation {
    condition     = contains(["indexed", "json"], var.list_strategy)
    error_message = "list_strategy must be either \"indexed\" or \"json\"."
  }
}

variable "kms_key_arn" {
  description = "KMS Key to be used to encrypt the SSM Parameter Store entries."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null ? true : can(regex("^arn:aws:kms", var.kms_key_arn))
    error_message = "Value must contain ARN, starting with \"arn:aws:kms\"."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ COMMON
# ---------------------------------------------------------------------------------------------------------------------
variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
