resource "aws_cloudwatch_log_group" "this" {
  name              = var.name_prefix
  retention_in_days = var.retention_in_days
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = var.name
  log_group_name = var.log_group_name
}