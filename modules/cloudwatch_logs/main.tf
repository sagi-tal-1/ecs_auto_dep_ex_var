resource "aws_cloudwatch_log_group" "this" {
  name              = var.name_prefix
  retention_in_days = var.retention_in_days
  tags              = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "${var.name_prefix}-stream"
  log_group_name = aws_cloudwatch_log_group.this.name
}

