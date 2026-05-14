variable "configuration_add_on" {
  description = "Arbitrarily nested HCL map / object to flatten."
  type        = any
  default     = {}
}

variable "prefix" {
  description = "Optional prefix prepended to every flattened key (e.g. \"/foundation\")."
  type        = string
  default     = ""
}

variable "separator" {
  description = "Separator used to join nested keys."
  type        = string
  default     = "/"
}

variable "list_strategy" {
  description = <<-EOT
    How list values are flattened:
      * "indexed" => one entry per element, key suffixed with the numeric index ("key/0", "key/1", ...)
      * "json"    => the whole list is stored as a single JSON-encoded string under the parent key
  EOT
  type        = string
  default     = "indexed"

  validation {
    condition     = contains(["indexed", "json"], var.list_strategy)
    error_message = "list_strategy must be either \"indexed\" or \"json\"."
  }
}
