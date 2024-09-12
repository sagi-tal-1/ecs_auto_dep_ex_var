resource "aws_cloudwatch_log_group" "ecs" {
  name              = var.log_group_name
  retention_in_days = var.retention_days
}

resource "aws_cloudwatch_log_stream" "nginx" {
  name           = "${var.log_group_name}-nginx"
  log_group_name = aws_cloudwatch_log_group.ecs.name
}

resource "aws_cloudwatch_log_stream" "nodejs" {
  name           = "${var.log_group_name}-nodejs"
  log_group_name = aws_cloudwatch_log_group.ecs.name
}
