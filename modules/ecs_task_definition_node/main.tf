# modules/
#moduls/ecs_task_definition_node/main.tf


resource "aws_ecs_task_definition" "app" {
  family                   = var.family
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  




  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.docker_image
      cpu       = var.cpu
      memory    = var.memory
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
       environment = [
        {
          name  = "SERVICE_IDENTITY"
          value = var.container_name
 # Unique identifier
        },
        {
          name  = "PORT"
          value = tostring(var.nodejs_port)
        },
        {
          name  = "TASK_INDEX"
          value = var.container_name
        }
      ]

      dockerLabels = {
        "app.service.identity" = var.container_name
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.log_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  
  ])

  volume {
    name      = "nginx-logs"
    host_path = "/var/log/ecs/nginx"
  }
}
