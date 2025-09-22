output "configuration_writer_role_name" {
  description = "Name of role used to write configuration into SSM Parameter Store."
  value       = aws_iam_role.configuration_writer.name
}

output "configuration_writer_role_arn" {
  description = "ARN of role used to write configuration into SSM Parameter Store."
  value       = aws_iam_role.configuration_writer.arn
}

output "configuration_reader_role_name" {
  description = "Name of role used to read configuration into SSM Parameter Store."
  value       = aws_iam_role.configuration_reader.name
}

output "configuration_reader_role_arn" {
  description = "ARN of role used to read configuration into SSM Parameter Store."
  value       = aws_iam_role.configuration_reader.arn
}
