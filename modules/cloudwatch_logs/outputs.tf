output "log_group_name" {
  value = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.ecs.arn
}

output "nginx_log_stream_name" {
  value = aws_cloudwatch_log_stream.nginx.name
}

output "nodejs_log_stream_name" {
  value = aws_cloudwatch_log_stream.nodejs.name
}

output "nginx_log_stream_arn" {
  value = aws_cloudwatch_log_stream.nginx.arn
}

output "nodejs_log_stream_arn" {
  value = aws_cloudwatch_log_stream.nodejs.arn
}
