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
          hostPort      = var.nginx_port
          protocol      = "tcp"
        }
      ]
      links = ["${var.container_name}-nodejs"]
      mountPoints = [
        {
          sourceVolume  = "nginx-config"
          containerPath = "/etc/nginx/nginx.conf"
          readOnly      = true
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_arn
          awslogs-region        = var.log_region
          awslogs-stream-prefix = "nginx"
          awslogs-create-group  = "false"
        }
      }
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
          hostPort      = var.node_port
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
          awslogs-group         = var.log_group_arn
          awslogs-region        = var.log_region
          awslogs-stream-prefix = "nodejs"
          awslogs-create-group  = "false"
        }
      }
    }
  ])

  volume {
    name      = "nginx-config"
    host_path = "${path.module}/nginx.conf"
  }

  depends_on = [
    var.nginx_log_stream_arn,
    var.nodejs_log_stream_arn
  ]
}