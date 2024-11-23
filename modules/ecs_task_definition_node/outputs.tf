# modules/ecs_task_defenition_node/outputs.tf

output "nodejs_port" {
  value = var.nodejs_port
}
output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}
