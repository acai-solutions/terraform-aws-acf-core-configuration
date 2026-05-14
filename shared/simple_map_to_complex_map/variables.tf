variable "flat_configuration" {
  description = "Flat map<string,string> as produced by `aws_ssm_parameters_by_path` / the flatten module."
  type        = map(string)
  default     = {}
}

variable "prefix" {
  description = "Prefix to strip from every key before unflattening (e.g. \"/foundation\")."
  type        = string
  default     = ""
}

variable "separator" {
  description = "Separator used inside the flat keys."
  type        = string
  default     = "/"
}
