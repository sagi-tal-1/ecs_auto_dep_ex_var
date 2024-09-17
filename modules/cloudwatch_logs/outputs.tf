
output "cloudwatch_log_group_name" {
  description = "Name of Cloudwatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of Cloudwatch log group"
  value       = aws_cloudwatch_log_group.this.arn
}

output "cloudwatch_log_stream_name" {
  description = "Name of Cloudwatch log stream"
  value       = aws_cloudwatch_log_stream.this.name
}

output "cloudwatch_log_stream_arn" {
  description = "ARN of Cloudwatch log stream"
  value       = aws_cloudwatch_log_stream.this.arn
}
