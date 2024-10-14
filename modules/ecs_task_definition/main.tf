resource "aws_ecs_task_definition" "app" {
  family                   = var.family
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.container_name}-nginx"
      image     = "nginx:latest"
      cpu       = var.cpu
      memory    = var.memory
      essential = true
      portMappings = [
        {
          containerPort = var.nginx_port
          hostPort      = 0  # Dynamic port mapping
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.cloudwatch_log_group_name
          awslogs-region        = var.log_region
          awslogs-stream-prefix = "nginx"
        }
      }
    }
  ])

  # We'll keep one volume for nginx logs
  volume {
    name      = "nginx-logs"
    host_path = "/var/log/ecs/nginx"
  }
}