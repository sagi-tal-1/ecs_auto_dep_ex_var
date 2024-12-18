#moduls/ecs_task_definition/main.tf
# resource "aws_ecs_task_definition" "app" {   
#   family                   = var.family   
#   requires_compatibilities = ["EC2"]   
#   network_mode            = "bridge"   
#   cpu                     = var.cpu   
#   memory                  = var.memory   
#   execution_role_arn      = var.execution_role_arn   
#   task_role_arn          = var.task_role_arn    
  
#   container_definitions = jsonencode([
#     {
#       # Init container definition
#       name      = "init-nginx-config"
#       image     = "${var.init_container_image}"
#       essential = false
#       cpu       = 128    # Smaller CPU allocation
#       memory    = 128    # Smaller memory allocation
      
#       mountPoints = [
#         {
#           sourceVolume  = "nginx-config"
#           containerPath = "/etc/nginx"  # Match the Nginx config directory
#           readOnly     = false
#         }
#       ]
#       environment = [
#         {
#           name  = "CLUSTER_NAME"
#           value = var.cluster_name
#         },
#         {
#           name  = "SERVICE_NAME"
#           value = var.service_name
#         },
#         {
#           name  = "AWS_DEFAULT_REGION"
#           value = var.aws_region
#         },
#         {
#           name  = "AWS_REGION"
#           value = var.aws_region
#         }
#       ]
#       logConfiguration = {         
#         logDriver = "awslogs"         
#         options = {           
#           awslogs-group         = "${var.log_group_name}-init"           
#           awslogs-region        = var.log_region           
#           awslogs-stream-prefix = "${var.log_stream_name_prefix}-init"         
#         }       
#       }
#     },
#     {       
#       # Main nginx container definition
#       name      = var.container_name        
#       image     = var.docker_image       
#       cpu       = 128 #var.cpu       
#       memory    = 128 #var.memory       
#       essential = true
#       healthCheck = {
#         command     = ["CMD-SHELL", "curl -f http://localhost:${var.nginx_port}/health || exit 1"]
#         interval    = 30
#         timeout     = 5
#         retries     = 3
#         startPeriod = 60
#       }
#       dependsOn = [
#         {
#           containerName = "init-nginx-config"
#           condition    = "COMPLETE"
#         }
#       ]             
#       portMappings = [         
#         {           
#           containerPort = var.nginx_port           
#           hostPort      = 80           
#           protocol      = "tcp"         
#         }       
#       ]                     
#       mountPoints = [       
#         {       
#           sourceVolume  = "nginx-config"       
#           containerPath = "/etc/nginx"       # Mount the entire nginx config directory
#           readOnly      = true       
#         }       
#       ]       
#       logConfiguration = {         
#         logDriver = "awslogs"         
#         options = {           
#           awslogs-group         = var.log_group_name           
#           awslogs-region        = var.log_region           
#           awslogs-stream-prefix = var.log_stream_name_prefix         
#         }       
#       }     
#     }   
#   ])  

#   volume { 
#     name = "nginx-config" 
#     docker_volume_configuration {
#       scope         = "task"
#       autoprovision = true
#       driver        = "local"
#     }
#   }  
# }
#----------------------------------------------------------------------------
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
      name      = var.container_name 
      image     = var.docker_image
      cpu       = var.cpu
      memory    = var.memory
      essential = true
     
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ],
      
      environment = [
        {
          name  = "NODEJS_SERVICE_NAME"
          value = var.nodejs_service_name
        }
        # Add any other necessary environment variables here
      ],

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      },

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.family}"
          awslogs-region        = var.log_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Create CloudWatch log group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.family}"
  retention_in_days = 30
}







# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg"
  description = "Security group for ECS tasks with Nginx"
  vpc_id      = var.vpc_id

  # Inbound rule for HTTP (port 80)
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Inbound rule for application port (3000)
  ingress {
    description      = "Application Port"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # Outbound rule - allow all traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ecs-tasks-security-group"
  }
}
#----------------------------------------------------------------------------
# resource "null_resource" "deployment_check" {
#   triggers = {
#     service_id = var.service_name_id
#   }

#   provisioner "local-exec" {
#     command = <<EOF
# #!/bin/bash
# set -e

# SERVICE_NAME="${var.service_name}"
# CLUSTER_NAME="${var.cluster_name}"
# MAX_ATTEMPTS=30
# SLEEP_TIME=20

# check_deployment() {
#     aws ecs describe-service-deployments \
#         --cluster $CLUSTER_NAME \
#         --service $SERVICE_NAME \
#         --query 'serviceDeployments[0]' \
#         --output json
# }

# for ((i=1; i<=$MAX_ATTEMPTS; i++)); do
#     echo "Checking deployment status (Attempt $i/$MAX_ATTEMPTS)..."
    
#     DEPLOYMENT_STATUS=$(check_deployment)
    
#     STATUS=$(echo $DEPLOYMENT_STATUS | jq -r '.status')
    
#     if [ "$STATUS" == "COMPLETED" ]; then
#         echo "Deployment completed successfully!"
#         exit 0
#     elif [ "$STATUS" == "FAILED" ] || [ "$STATUS" == "ROLLBACK_COMPLETED" ] || [ "$STATUS" == "ROLLBACK_FAILED" ]; then
#         echo "Deployment failed with status: $STATUS"
#         echo "Deployment details:"
#         echo $DEPLOYMENT_STATUS | jq '.'
        
#         # Get deployment failures
#         FAILURES=$(aws ecs describe-service-deployments \
#             --cluster $CLUSTER_NAME \
#             --service $SERVICE_NAME \
#             --query 'failures[]' \
#             --output json)
            
#         if [ "$FAILURES" != "[]" ]; then
#             echo "Deployment failures:"
#             echo $FAILURES | jq '.'
#         fi
        
#         exit 1
#     fi
    
#     echo "Deployment in progress (Status: $STATUS). Waiting $${SLEEP_TIME} seconds..."
#     sleep $SLEEP_TIME
# done

# echo "Deployment check timed out after $MAX_ATTEMPTS attempts"
# exit 1
# EOF
#   }

#   depends_on = [aws_ecs_task_definition.app]
# }






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
#           containerPort = var.nginx_port           
#           hostPort      = 80           
#           protocol      = "tcp"         
#         }       
#       ],                     
#       mountPoints = [       
#         {       
#           sourceVolume  = "nginx-config"       
#           containerPath = "/etc/nginx/nginx.conf"       
#           readOnly      = true       
#         }       
#       ],       
#       logConfiguration = {         
#         logDriver = "awslogs"         
#         options = {           
#           awslogs-group         = var.log_group_name           
#           awslogs-region        = var.log_region           
#           awslogs-stream-prefix = var.log_stream_name_prefix         
#         }       
#       }     
#     }   
#   ])  

#   volume { 
#     name = "nginx-config" 
#     host_path = "${path.module}/config/nginx.conf" 
#   }  
# }  

# resource "aws_security_group" "ecs_tasks" {   
#   name        = "ecs-tasks-sg"   
#   description = "Security group for ECS tasks with Nginx"   
#   vpc_id      = var.vpc_id    

#   # Inbound rule for HTTP (port 80)   
#   ingress {     
#     description      = "HTTP from VPC"     
#     from_port        = 80     
#     to_port          = 80     
#     protocol         = "tcp"     
#     cidr_blocks      = ["0.0.0.0/0"]     
#     ipv6_cidr_blocks = ["::/0"]   
#   }    

#   # Inbound rule for application port (3000)   
#   ingress {     
#     description      = "Application Port"     
#     from_port        = 3000     
#     to_port          = 3000     
#     protocol         = "tcp"     
#     cidr_blocks      = ["0.0.0.0/0"]   
#   }    

#   # Outbound rule - allow all traffic   
#   egress {     
#     from_port        = 0     
#     to_port          = 0     
#     protocol         = "-1"     
#     cidr_blocks      = ["0.0.0.0/0"]     
#     ipv6_cidr_blocks = ["::/0"]   
#   }    

#   tags = {     
#     Name = "ecs-tasks-security-group"   
#   } 
# }

# # Add the null_resource after both task definitions
# resource "null_resource" "nginx_config_generator" {
#   triggers = {
#     ecs_service_id = var.ecs_service.id # Reference to the ECS service
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       #!/bin/bash
# #!/bin/bash
# set -e

# # Enhanced logging function using tr for uppercase conversion
# log() {
#     local level=$(echo "$1" | tr '[:lower:]' '[:upper:]')
#     local message="$2"
#     local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
#     echo "[$timestamp] [$level] $message"
# }

# # Number of expected tasks (passed as an argument)
# EXPECTED_TASKS="2"
# CLUSTER_NAME="demo-cluster-2f226f6e"
# SERVICE_NAME="ECS_service-ecs-service-node-2f226f6e"
# MAX_WAIT_TIME=300  # 5 minutes total wait time
# WAIT_INTERVAL=10   # Check every 10 seconds

# # Enhanced logging function to wait for task definition
# wait_for_task_definition() {
#     log "info" "Starting wait_for_task_definition function"
#     local max_attempts=30
#     local attempt=1
#     local task_def_arn=""
  
#     while [ $attempt -le $max_attempts ]; do
#         log "debug" "Attempting to list task definitions (attempt $attempt/$max_attempts)"
#         task_def_arn=$(aws ecs list-task-definitions \
#             --family-prefix your-task-family \
#             --sort DESC \
#             --max-items 1 \
#             --query 'taskDefinitionArns[0]' \
#             --output text)
    
#         if [ ! -z "$task_def_arn" ] && [ "$task_def_arn" != "None" ]; then
#             log "success" "Task definition found: $task_def_arn"
#             echo "$task_def_arn"
#             return 0
#         fi
    
#         log "warn" "Task definition not found. Waiting 90 seconds before next attempt..."
#         sleep 90
#         ((attempt++))
#     done
  
#     log "error" "Failed to find task definition after $max_attempts attempts"
#     return 1
# }

# # Enhanced logging for task readiness check
# wait_for_tasks() {
#     log "info" "Starting wait_for_tasks function"
#     local start_time=$(date +%s)
#     local current_time=$start_time
#     local working_tasks=0
#     local valid_tasks_info=""

#     log "info" "Waiting for tasks. Expected: $EXPECTED_TASKS"

#     while [ $((current_time - start_time)) -lt $MAX_WAIT_TIME ]; do
#         log "debug" "Attempting to list running tasks"
#         # List tasks for the service
#         TASKS=$(aws ecs list-tasks \
#             --cluster "$CLUSTER_NAME" \
#             --service-name "$SERVICE_NAME" \
#             --desired-status RUNNING \
#             --query 'taskArns[]' \
#             --output text)

#         if [ -n "$TASKS" ]; then
#             log "info" "Found tasks: $TASKS"
            
#             # Get task details
#             log "debug" "Describing tasks"
#             TASK_INFO=$(aws ecs describe-tasks \
#                 --cluster "$CLUSTER_NAME" \
#                 --tasks $TASKS)

#             # Process task information
#             while IFS= read -r task; do
#                 log "debug" "Processing task: $task"
                
#                 CONTAINER_INSTANCE=$(echo "$task" | jq -r '.[1] // empty')
#                 HOST_PORT=$(echo "$task" | jq -r '.[2][0] // empty')
                
#                 log "info" "Container Instance: $CONTAINER_INSTANCE, Host Port: $HOST_PORT"
                
#                 # Validate IP and port
#                 if [ -n "$HOST_PORT" ] && [ "$HOST_PORT" -gt 0 ] 2>/dev/null; then
#                     log "debug" "Retrieving EC2 instance details"
#                     # Get container instance details
#                     EC2_INFO=$(aws ecs describe-container-instances \
#                         --cluster "$CLUSTER_NAME" \
#                         --container-instances "$CONTAINER_INSTANCE" \
#                         --query 'containerInstances[].[ec2InstanceId,containerInstanceArn]' \
#                         --output json)

#                     # Get EC2 instance ID
#                     EC2_ID=$(echo "$EC2_INFO" | jq -r '.[][] | select(contains("i-"))' | tr -d '\n')
#                     log "info" "EC2 Instance ID: $EC2_ID"

#                     # Get private IP
#                     PRIVATE_IP=$(aws ec2 describe-instances \
#                         --instance-ids "$EC2_ID" \
#                         --query 'Reservations[].Instances[].PrivateIpAddress' \
#                         --output text)
#                     log "info" "Private IP: $PRIVATE_IP"

#                     # Validate connection
#                     log "debug" "Testing connection to $PRIVATE_IP:$HOST_PORT"
#                     if timeout 5 bash -c "echo > /dev/tcp/$PRIVATE_IP/$HOST_PORT" 2>/dev/null; then
#                         valid_tasks_info+="        server $${PRIVATE_IP}:$${HOST_PORT}; # Task: $(echo "$task" | jq -r '.[0]')\n"
#                         ((working_tasks++))
#                         log "success" "Successfully validated connection to $${PRIVATE_IP}:$${HOST_PORT}"
#                     else
#                         log "warn" "Connection test failed for $PRIVATE_IP:$HOST_PORT"
#                     fi
#                 fi
#             done <<< "$(echo "$TASK_INFO" | jq -c '.tasks[]')"

#             # If we have working tasks, generate config
#             if [ "$working_tasks" -gt 0 ]; then
#                 log "info" "Generating Nginx configuration with $working_tasks working tasks"
#                 mkdir -p modules/ecs_task_definition/config
#                 cat > modules/ecs_task_definition/config/nginx.conf <<EOF
# http {
#     upstream backend_servers {
# $valid_tasks_info    }
    
#     server {
#         listen 80;
        
#         location / {
#             proxy_pass http://backend_servers;
#             proxy_set_header Host \$host;
#             proxy_set_header X-Real-IP \$remote_addr;
#         }
#     }
# }
# EOF
#                 log "success" "Nginx configuration generated successfully"
#                 break
#             fi
#         else
#             log "warn" "No tasks found in current iteration"
#         fi

#         sleep $WAIT_INTERVAL
#         current_time=$(date +%s)
#     done

#     # Final checks and error handling
#     if [ "$working_tasks" -eq 0 ]; then
#         log "error" "No valid tasks found"
#         return 1
#     fi

#     return 0
# }

# # Main script execution with logging
# main() {
#     log "info" "Starting ECS Deployment Script"

#     # Capture start time
#     local script_start_time=$(date +%s)

#     log "debug" "Calling wait_for_task_definition"
#     TASK_DEF_ARN=$(wait_for_task_definition)
#     log "success" "Task Definition ARN: $TASK_DEF_ARN"

#     log "debug" "Listing running tasks"
#     RUNNING_TASKS=$(aws ecs list-tasks \
#         --cluster "$CLUSTER_NAME" \
#         --service-name "$SERVICE_NAME" \
#         --desired-status RUNNING \
#         --query 'taskArns[]' \
#         --output text)
#     log "info" "Current Running Tasks: $RUNNING_TASKS"

#     # Stop running tasks
#     log "info" "Stopping existing tasks"
#     for task in $RUNNING_TASKS; do
#         log "debug" "Stopping task: $task"
#         aws ecs stop-task \
#             --cluster "$CLUSTER_NAME" \
#             --task "$task"
#     done

#     log "debug" "Waiting for tasks to stop"
#     aws ecs wait tasks-stopped \
#         --cluster "$CLUSTER_NAME" \
#         --tasks $RUNNING_TASKS

#     log "debug" "Updating service with desired count 0"
#     aws ecs update-service \
#         --cluster "$CLUSTER_NAME" \
#         --service "$SERVICE_NAME" \
#         --desired-count 0

#     # Wait a few seconds for the service to scale down
#     log "info" "Waiting for service to scale down"
#     sleep 10

#     log "debug" "Updating service with final task definition"
#     aws ecs update-service \
#         --cluster "$CLUSTER_NAME" \
#         --service "$SERVICE_NAME" \
#         --task-definition "arn:aws:ecs:us-east-1:010575877879:task-definition/nginx-task-2f226f6e:2" \
#         --force-new-deployment

#     log "info" "Running task waiting and configuration generation"
#     if ! wait_for_tasks; then
#         log "error" "Failed to initialize tasks"
#         exit 1
#     fi

#     # Calculate and log total script execution time
#     local script_end_time=$(date +%s)
#     local total_execution_time=$((script_end_time - script_start_time))
#     log "success" "Deployment configuration completed in $total_execution_time seconds"
# }



#     EOT

#     interpreter = ["/bin/bash", "-c"]
#   }

#   depends_on = [var.ecs_service]
# }








#-----------------------------------
# resource "null_resource" "nginx_config_generator" {
#   triggers = {
#     ecs_service_id = var.ecs_service.id 
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       #!/bin/bash
#       set -e

#       # Number of expected tasks (passed as an argument)
#       EXPECTED_TASKS="${var.expected_nodejs_tasks}"
#       CLUSTER_NAME="${var.cluster_name}"
#       SERVICE_NAME="${var.ecs_service.name}"
#       MAX_WAIT_TIME=300  # 5 minutes total wait time
#       WAIT_INTERVAL=10   # Check every 10 seconds

#       # Logging function
#       log_status() {
#         echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
#       }

#       # Create initial placeholder nginx configuration
#       mkdir -p ${path.module}/config
#       cat > ${path.module}/config/nginx.conf <<EOF
# http {
#     server {
#         listen 80;
        
#         location / {
#             return 503 'Services are initializing or partially unavailable. Please try again later.';
#             add_header Content-Type text/plain;
#         }

#         location /health {
#             return 200 'Services status: Initializing';
#             add_header Content-Type text/plain;
#         }
#     }
# }
# EOF

#       # Function to check task readiness
#       wait_for_tasks() {
#         local start_time=$(date +%s)
#         local current_time=$start_time
#         local available_tasks=0
#         local valid_tasks_info=""

#         log_status "Waiting for tasks. Expected: $EXPECTED_TASKS"

#         while [ $((current_time - start_time)) -lt $MAX_WAIT_TIME ]; do
#           # List tasks for the service
#           TASKS=$(aws ecs list-tasks \
#             --cluster "$CLUSTER_NAME" \
#             --service-name "$SERVICE_NAME" \
#             --desired-status RUNNING \
#             --query 'taskArns[]' \
#             --output text)

#           # Count running tasks
#           available_tasks=$(echo "$TASKS" | wc -w)

#           log_status "Current running tasks: $available_tasks"

#           # If at least one task is running, start collecting task info
#           if [ "$available_tasks" -gt 0 ]; then
#             # Get detailed task information
#             TASK_INFO=$(aws ecs describe-tasks \
#               --cluster "$CLUSTER_NAME" \
#               --tasks $TASKS \
#               --query 'tasks[].[taskArn,containerInstanceArn,containers[].networkBindings[].hostPort]' \
#               --output json)

#             # Process task information
#             working_tasks=0
#             valid_tasks_info=""

#             echo "$TASK_INFO" | jq -c '.[]' | while read -r task; do
#               CONTAINER_INSTANCE=$(echo "$task" | jq -r '.[1] // empty')
#               HOST_PORT=$(echo "$task" | jq -r '.[2][0] // empty')
              
#               # Validate IP and port
#               if [ -n "$HOST_PORT" ] && [ "$HOST_PORT" -gt 0 ] 2>/dev/null; then
#                 # Get container instance details
#                 EC2_INFO=$(aws ecs describe-container-instances \
#                   --cluster "$CLUSTER_NAME" \
#                   --container-instances "$CONTAINER_INSTANCE" \
#                   --query 'containerInstances[].[ec2InstanceId,containerInstanceArn]' \
#                   --output json)

#                 # Get EC2 instance ID
#                 EC2_ID=$(echo "$EC2_INFO" | jq -r '.[][] | select(contains("i-"))' | tr -d '\n')

#                 # Get private IP
#                 PRIVATE_IP=$(aws ec2 describe-instances \
#                   --instance-ids "$EC2_ID" \
#                   --query 'Reservations[].Instances[].PrivateIpAddress' \
#                   --output text)

#                 # Validate connection
#                 if timeout 5 bash -c "echo > /dev/tcp/$PRIVATE_IP/$HOST_PORT" 2>/dev/null; then
#                   valid_tasks_info+="        server $${PRIVATE_IP}:$${HOST_PORT}; # Task: $(echo "$task" | jq -r '.[0]')\n"
#                   ((working_tasks++))
#                   log_status "Successfully validated connection to $${PRIVATE_IP}:$${HOST_PORT}"
#                 fi
#               fi
#             done

#             # If we have working tasks, generate config
#             if [ "$working_tasks" -gt 0 ]; then
#               cat > ${path.module}/config/nginx.conf <<EOF
# http {
#     upstream backend_servers {
# $valid_tasks_info    }
    
#     server {
#         listen 80;
        
#         location / {
#             proxy_pass http://backend_servers;
#             proxy_set_header Host \$host;
#             proxy_set_header X-Real-IP \$remote_addr;
#         }
#     }
# }
# EOF
#               break
#             fi
#           fi

#           sleep $WAIT_INTERVAL
#           current_time=$(date +%s)
#         done

#         # Final checks and error handling
#         if [ "$working_tasks" -eq 0 ]; then
#           log_status "No valid tasks found"
#           return 1
#         fi

#         return 0
#       }

#       # Run the task waiting and configuration generation
#       if ! wait_for_tasks; then
#         echo "Failed to initialize tasks"
#         exit 1
#       fi

#       echo "Deployment configuration completed"
#     EOT

#     interpreter = ["/bin/bash", "-c"]
#   }

#   depends_on = [var.ecs_service]
# }













# resource "aws_ecs_task_definition" "app" {
#   family                   = var.family
#   requires_compatibilities = ["EC2"]
#   network_mode            = "bridge"
#   cpu                     = var.cpu
#   memory                  = var.memory
#   execution_role_arn      = var.execution_role_arn
#   task_role_arn           = var.task_role_arn

#   container_definitions = jsonencode([
#     {
#       name      = var.container_name 
#       image     = var.docker_image
#       cpu       = var.cpu
#       memory    = var.memory
#       essential = true
     
#       portMappings = [
#         {
#           containerPort = var.nginx_port
#           hostPort      = 80
#           protocol      = "tcp"
#         }
#       ],
      
      
#       # mountPoints = [
#       #   {
#       #     sourceVolume  = "nginx-config"
#       #     containerPath = "/etc/nginx/nginx.conf"
#       #     readOnly      = true
#       #   }
#       # ],
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = var.log_group_name
#           awslogs-region        = var.log_region
#           awslogs-stream-prefix = var.log_stream_name_prefix
#         }
#       }
#     }
#   ])

# #  volume {
# #     name = "nginx-config"
# #     host_path = "${path.module}/nginx_config/nginx.conf"
# #   }

# #   volume {
# #     name = "nginx-logs"
# #     host_path = "/var/log/ecs/nginx"
# #   }

# }

# # Security group for ECS tasks
# resource "aws_security_group" "ecs_tasks" {
#   name        = "ecs-tasks-sg"
#   description = "Security group for ECS tasks with Nginx"
#   vpc_id      = var.vpc_id

#   # Inbound rule for HTTP (port 80)
#   ingress {
#     description      = "HTTP from VPC"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   # Inbound rule for application port (3000)
#   ingress {
#     description      = "Application Port"
#     from_port        = 3000
#     to_port          = 3000
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }

#   # Outbound rule - allow all traffic
#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "ecs-tasks-security-group"
#   }
# }