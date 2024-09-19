resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.name_prefix}-{instance_id}"
  retention_in_days = var.retention_in_days



  depends_on = [
    aws_cloudwatch_log_group.this
  ]
}