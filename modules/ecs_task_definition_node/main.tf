# modules/
#moduls/ecs_task_definition_node/main.tf
# modules/ecs_task_definition_node/main.tf
data "aws_region" "current" {}

locals {
  docker_labels = {
    "app.service.identity" = "my-container-nodejs-#{container:DockerId}"
    "service"             = "nodejs"
    "custom.container-name" = "#{aws:TaskARN}"
    "container-name"      = var.container_name
    "task-definition-family" = var.family
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.family
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.docker_image
      cpu       = var.cpu
      memory    = var.memory
      essential = true

      portMappings = [
        {
          containerPort = var.nodejs_port
          hostPort     = 0
          protocol     = "tcp"
        }
      ]

      environment = [
        {
          name  = "SERVICE_IDENTITY"
          value = var.container_name
        },
        {
          name  = "PORT"
          value = tostring(var.nodejs_port)
        },
        {
          name  = "TASK_INSTANCE"
          value = "#{container:DockerId}"
        },
        {
          name  = "TASK_ID"
          value = "#{aws:TaskARN}"
        },
        {
          name  = "SERVICE_DISCOVERY_NAME"
          value = "${var.service_discovery_service_name}.${var.service_discovery_namespace}"
        },
        {
          name  = "DISCOVERY_INTERVAL"
          value = "30"
        },
        {
          name  = "ECS_CONTAINER_METADATA_URI"
          value = "#{ECS_CONTAINER_METADATA_URI_V4}"
        },
        {
          name  = "ECS_CLUSTER"
          value = var.cluster_name
        },
        {
          name  = "ECS_CONTAINER_NAME"
          value = var.container_name
        },
        {
          name  = "ECS_SERVICE_NAME"
          value = var.service_name
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        },
        {
          name  = "CONTAINER_ID"
          value = "#{container:DockerId}"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "nginx-logs"
          containerPath = "/var/log/nginx"
          readOnly      = false
        }
      ]

      dockerLabels = local.docker_labels

      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:${var.nodejs_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.log_region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
          mode                  = "non-blocking"
          max-buffer-size       = "4m"
        }
      }
    }
  ])

  volume {
    name      = "nginx-logs"
    host_path = "/var/log/ecs/nginx"
  }

  tags = {
    Environment = var.environment
    Service     = var.container_name
    Managed-by  = "terraform"
  }
}








# resource "aws_ecs_task_definition" "app" {
#   family                   = var.family
#   requires_compatibilities = ["EC2"]
#   network_mode             = "bridge"
#   cpu                      = var.cpu
#   memory                   = var.memory
#   execution_role_arn       = var.execution_role_arn
#   task_role_arn            = var.task_role_arn
  
#   container_definitions = jsonencode([
#     {
#       name      = var.container_name
#       image     = var.docker_image
#       cpu       = var.cpu
#       memory    = var.memory
#       essential = true

#       portMappings = [
#         {
#           containerPort = 3000
#           hostPort      = 3000
#           protocol      = "tcp"
#         }
#       ]
#        environment = [
#         {
#           name  = "SERVICE_IDENTITY"
#           value = var.container_name
#                  # Unique identifier
#         },
#         {
#           name  = "PORT"
#           value = tostring(var.nodejs_port)
#         },
#         {
#           name  = "TASK_INDEX"
#           value = var.container_name
#         },
#         {
#       "name": "SERVICE_DISCOVERY_NAME",
#       "value": "tasks.nodejs-service"  // Adjust this to match your service discovery name
#     },
#     {
#       "name": "DISCOVERY_INTERVAL",
#       "value": "30"
#     }
    

#       dockerLabels = {
#         "app.service.identity" = var.container_name
#       }

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = var.log_group_name
#           awslogs-region        = var.log_region
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#     }
  
#   ])

#   volume {
#     name      = "nginx-logs"
#     host_path = "/var/log/ecs/nginx"
#   }
# }
