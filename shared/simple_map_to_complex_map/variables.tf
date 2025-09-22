variable "flat_configuration" {
  description = "Flat configuration-map."
  type        = map(string)
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