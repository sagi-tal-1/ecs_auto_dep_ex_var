resource "aws_ecs_task_definition" "nginx_temp" {   
  family                   = var.family   
  requires_compatibilities = ["EC2"]   
  network_mode             = "bridge"   
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
          containerPort = var.nginx_port           
          hostPort      = 80           
          protocol      = "tcp"         
        }       
      ],                     
      mountPoints = [       
        {       
          sourceVolume  = "nginx-config-temp"       
          containerPath = "/etc/nginx/nginx.conf"       
          readOnly      = true       
        }       
      ],       
      logConfiguration = {         
        logDriver = "awslogs"         
        options = {           
          awslogs-group         = var.log_group_name           
          awslogs-region        = var.log_region           
          awslogs-stream-prefix = "${var.log_stream_name_prefix}-temp"         
        }       
      }     
    }   
  ])  

  volume { 
    name = "nginx-config-temp" 
    host_path = "${path.module}/config/nginx.temp.conf" # Temporary configuration
  }  
}
