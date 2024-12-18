
output "cloudwatch_log_group_name" {
  description = "Name of Cloudwatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of Cloudwatch log group"
  value       = aws_cloudwatch_log_group.this.arn
}

output "log_stream_name" {
  description = "The name of the CloudWatch Log Stream"
  value       = aws_cloudwatch_log_stream.this.name
}


