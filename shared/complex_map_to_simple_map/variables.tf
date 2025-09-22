variable "configuration_add_on" {
  description = "Complex map of configuration add-on."
  type        = any
}

variable "prefix" {
  description = "Prefix to the configuration-item keys."
  type        = string
  default     = "/foundation"
}

variable "python_name" {
  description = "Name of the Python executeable. e.g. python or python3"
  type        = string
  default     = "python"
}