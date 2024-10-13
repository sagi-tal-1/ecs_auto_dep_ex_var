# Updated ECS Task Definition
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
      cpu       = var.cpu / 2
      memory    = var.memory / 2
      essential = true
      portMappings = [
        {
          containerPort = var.nginx_port
          hostPort      = 0  # Changed to 0 for dynamic port mapping
          protocol      = "tcp"
        }
      ]
      links = ["${var.container_name}-nodejs"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.cloudwatch_log_group_name
          awslogs-region        = var.log_region
          awslogs-stream-prefix = "nginx"
        }
      }
      mountPoints = [
        {
          sourceVolume  = "nginx-config"
          containerPath = "/etc/nginx/nginx.conf"
          readOnly      = true
        },
        {
          sourceVolume  = "nginx-logs"
          containerPath = "/var/log/nginx"
          readOnly      = false
        }
      ]
    },
    {
      name      = "${var.container_name}-nodejs"
      image     = "node:latest"
      cpu       = var.cpu / 2
      memory    = var.memory / 2
      essential = true
      portMappings = [
        {
          containerPort = var.node_port
          hostPort      = 0  # Changed to 0 for dynamic port mapping
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "NODE_PORT"
          value = tostring(var.node_port)
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.cloudwatch_log_group_name
          awslogs-region        = var.log_region
          awslogs-stream-prefix = "node-js"
        }
      }
      mountPoints = [
        {
          sourceVolume  = "nodejs-logs"
          containerPath = "/app/logs"
          readOnly      = false
        }
      ]
    }
  ])

  volume {
    name      = "nginx-config"
    host_path = "/etc/nginx/nginx.conf"
  }

  volume {
    name      = "nginx-logs"
    host_path = "/var/log/ecs/nginx"
  }

  volume {
    name      = "nodejs-logs"
    host_path = "/var/log/ecs/nodejs"
  }
}