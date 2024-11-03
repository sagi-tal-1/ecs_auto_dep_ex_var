terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
  }
}

provider "aws" {
  region      = "us-east-1"
  retry_mode  = "standard"
  max_retries = 3
}


resource "random_id" "unique" {
  byte_length = 4
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ecs-instance-key-${random_id.unique.hex}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.cwd}/${aws_key_pair.generated_key.key_name}.pem"
  file_permission = "0600"
}

resource "local_file" "user_data" {
  content  = <<-EOF
# Generated on: ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}
# Cluster: ${module.ecs_cluster.cluster_name}
# Region: ${var.aws_region}

${module.ecs_launch_template.rendered_user_data}
EOF

  filename = "${path.root}/rendered_user_data.sh"
  file_permission = "0644"
}

data "aws_availability_zones" "available" {
  state = "available"

}

# Networking -----------------------
# 1 VPC Module
locals {
  azs_count = 2
  azs_names = slice(data.aws_availability_zones.available.names, 0, 2)

  # Added capacity_provider_name declaration
  capacity_provider_name = "demo-capacity-provider-${random_id.unique.hex}"

 
}

module "vpc" {
  source = "./modules/vpc"
  name   = "demo-vpc-${random_id.unique.hex}"

  cidr_block         = var.vpc_cidr
  availability_zones = local.azs_names
  existing_vpc_id    = ""


}

# 2. Internet Gateway Module
module "internet_gateway" {
  source      = "./modules/internet_gateway"
  vpc_id      = module.vpc.vpc_id
  name        = "demo-igw-${random_id.unique.hex}"
  azs_count   = local.azs_count
  azs_names   = local.azs_names
  create_eips = true
}
# First, let's modify how we get existing EIPs
data "aws_eips" "all" {
  filter {
    name   = "domain"
    values = ["vpc"]
  }
}

# Then create only the EIPs we actually need
resource "aws_eip" "eip" {
  count = local.azs_count  # This will create only the number of EIPs needed for NAT gateways

  domain                    = "vpc"
  associate_with_private_ip = null

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Managed-EIP-${count.index + 1}"
  }
}

# Update the EIP disassociation resource
resource "null_resource" "eip_disassociation" {
  count = length(aws_eip.eip)

  triggers = {
    eip_id = aws_eip.eip[count.index].id
  }

  provisioner "local-exec" {
    command = <<-EOF
      ASSOCIATION_ID=$(aws ec2 describe-addresses --allocation-ids ${aws_eip.eip[count.index].id} --query 'Addresses[0].AssociationId' --output text)
      if [ "$ASSOCIATION_ID" != "None" ] && [ -n "$ASSOCIATION_ID" ]; then
        aws ec2 disassociate-address --association-id $ASSOCIATION_ID
      fi
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      aws ec2 release-address --allocation-id ${self.triggers.eip_id} || true
    EOF
  }

  depends_on = [module.internet_gateway]
}

# 3. NAT Gateway Module
module "nat_gateway" {
  source            = "./modules/nat_gateway"
  name_prefix       = var.name_prefix // Changed from var.name
  public_subnet_ids = module.vpc.public_subnet_ids
  vpc_id            = module.vpc.vpc_id
  region            = var.aws_region // Changed from var.region
  az_count          = local.azs_count

depends_on = [module.vpc]

}

# 4. Route Table Module
module "route_table" {
  source              = "./modules/route_table"
  vpc_id              = module.vpc.vpc_id
  name                = var.name_prefix // Changed from var.name
  internet_gateway_id = module.internet_gateway.internet_gateway_id
  subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  availability_zones  = local.azs_names // Changed from var.availability_zones
  nat_gateway_id      = module.nat_gateway.nat_gateway_id
  public_subnet_ids = module.vpc.public_subnet_ids

depends_on = [
    module.internet_gateway,
    module.nat_gateway,
    module.vpc
  ]


}

#Security -----------------------
# 5. Security Group Modules
module "ecs_node_sg" {
  source                = "./modules/ecs_node_sg"
  name_prefix           = "demo-ecs-sg-${random_id.unique.hex}"
  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.alb.security_group_id
  nginx_port            = module.ecs_task_definition.nginx_port
  node_port             = module.ecs_task_definition.node_port
}

# Load Balancer -----------------------
# 6. Application Load Balancer (ALB) Module
module "alb" {
  source      = "./modules/alb"
  name_prefix = "demo-alb-${random_id.unique.hex}"
  alb_name    = "demo-alb-${random_id.unique.hex}"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  nginx_port  = module.ecs_task_definition.nginx_port

  
}

# IAM Roles -----------------------
# 7. ECS Node Role Module
module "ecs_node_role" {
  source              = "./modules/ecs_node_role"
  role_name_prefix    = "demo-ecs-node-role-${random_id.unique.hex}"
  profile_name_prefix = "demo-ecs-node-profile-${random_id.unique.hex}"
}

# 8. ECS Task Roles Module
module "ecs_task_role" {
  source                = "./modules/ecs_task_role"
  task_role_name_prefix = "demo-ecs-task-role-${random_id.unique.hex}"
  exec_role_name_prefix = "demo-ecs-exec-role-${random_id.unique.hex}"
}

# Logging ----------------------- 
# 9. AWS CloudWatch Logs
module "log_group" {
  source            = "./modules/cloudwatch_logs"
  name_prefix       = "log_group-${random_id.unique.hex}"
  retention_in_days = var.cloudwatch_logs_retention_days

tags = {
    Environment = "production"
    Application = "ecs-cluster"
  }

}

# ECS Cluster and related resources ----------------------- 
# 10. ECS Cluster Module

module "ecs_cluster" {
  source       = "./modules/ecs_cluster"
  name_prefix  = "demo-${random_id.unique.hex}"
  cluster_name = "demo-cluster-${random_id.unique.hex}"
  asg_arn = module.ecs_asg.asg_arn

  depends_on = [module.vpc]
}


# 11. ECS Launch Template Module ----------------------- 
# Get the latest ECS-optimized AMI in the region
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
     values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"] #amzn2-ami-ecs-hvm-*-x86_64-ebs Without the use of SSM agent] --- al2023-ami-ecs-hvm-*-x86_64 with ssm agent
  }

  filter {
    name   = "owner-id"
    values = ["591542846629"] # AWS ECS Optimized AMI account owner ID
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
 filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

    filter {
    name   = "architecture"
    values = ["x86_64"]
  }

}


module "ecs_launch_template" {
  source      = "./modules/ecs_launch_template"
  name_prefix = "demo-ecs-ec2-${random_id.unique.hex}"
  key_name    = aws_key_pair.generated_key.key_name
  ami_id      = data.aws_ami.ecs_optimized.id
  # "ami-05dc81a6311c42a6e"
  instance_type            = "t2.micro"
  security_group_id        = module.ecs_node_sg.security_group_id
  iam_instance_profile_arn = module.ecs_node_role.ecs_instance_profile_arn
  cluster_name             = module.ecs_cluster.cluster_name
  log_group_name           = module.log_group.cloudwatch_log_group_name
  dockerhub_username       = local.dockerhub_credentials.username
  dockerhub_password       = local.dockerhub_credentials.password
  public_subnet_ids = module.vpc.public_subnet_ids 
  log_file                 = "/var/log/ecs/user_data.log"  # <-- Add this line
  error_log                = "/var/log/ecs_error.log"

 
  
 tags = {
    Environment = "production"
    Terraform   = "true"
    ECSCluster  = module.ecs_cluster.cluster_name
  }

 depends_on = [module.ecs_cluster] 
 
}

resource "local_file" "rendered_user_data" {
  content  = module.ecs_launch_template.rendered_user_data
  filename = "${path.module}/rendered_user_data.sh"
}


data "aws_instances" "ecs_instances" {
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [module.ecs_asg.autoscaling_group_name]
  }
  depends_on = [module.ecs_asg]
}



#-------------------------------------------------


# 12. Scaling Group Module ----------------------- 
module "ecs_asg" {
  source             = "./modules/autosacling_group"
  name_prefix        = "demo-ecs-asg-${random_id.unique.hex}"
  subnet_ids         = module.vpc.public_subnet_ids
  min_size           = 1
  max_size           = 2
  desired_capacity   = 1
  launch_template_id = module.ecs_launch_template.launch_template_id
  instance_name      = "demo-ecs-instance-${random_id.unique.hex}"
 
  
  depends_on = [module.ecs_launch_template]

}



#----------------------------------------------------------
data "aws_ecs_cluster" "this" {
  cluster_name = module.ecs_cluster.cluster_name
  depends_on   = [module.ecs_cluster]
}

# 13. ecs_capacity_provider Module -----------------------
module "ecs_capacity_provider" {
  source                 = "./modules/ecs_capacity_provider"
  capacity_provider_name = local.capacity_provider_name
  asg_arn                = module.ecs_asg.asg_arn
  # Fixd cluster_name ref to data
  cluster_name = data.aws_ecs_cluster.this.cluster_name

  weight                = 100
  max_scaling_step_size = 1
  min_scaling_step_size = 1
  target_capacity       = 100
  base_capacity         = 1

 depends_on = [module.ecs_asg, module.ecs_cluster]

}

# 14. ECS Task Definition Module -----------------------
locals {
  dockerhub_credentials = jsondecode(file("${path.module}/dockerhub_credentials.json"))
}

module "ecs_task_definition" {
  source                    = "./modules/ecs_task_definition"
  family                    = "nginx-task-${random_id.unique.hex}"
  container_name            = "nginx"
  docker_image              = "nginx:latest"
  log_group_name            = module.log_group.cloudwatch_log_group_name
  log_stream_prefix         = "ecs"
  cpu                       = 256
  memory                    = 512
  nginx_port                = 80
  task_role_arn             = module.ecs_task_role.task_role_arn
  execution_role_arn        = module.ecs_task_role.execution_role_arn
  log_region                = var.aws_region
  cloudwatch_log_group_name = module.log_group.cloudwatch_log_group_name
  cloudwatch_log_group_arn  = module.log_group.cloudwatch_log_group_arn


  depends_on = [module.log_group]
}
resource "null_resource" "docker_login" {
  provisioner "local-exec" {
    command = "docker login -u ${local.dockerhub_credentials.username} -p ${local.dockerhub_credentials.password}"
  }
}


# 15. ECS Service Module -----------------------
module "ecs_service" {
  source                    = "./modules/ecs_service"
  name_prefix               = var.name_prefix
  service_name              = "${var.name_prefix}-ecs-service-${random_id.unique.hex}"
  cluster_id                = module.ecs_cluster.cluster_id
  ecs_cluster_id            = module.ecs_cluster.ecs_cluster_id
  task_definition_arn       = module.ecs_task_definition.task_definition_arn
  desired_count             = 1
  subnet_ids                = module.vpc.public_subnet_ids
  target_group_arn          = module.alb.target_group_arn
  container_name            = module.ecs_task_definition.container_name
  nginx_port                = module.ecs_task_definition.nginx_port
  capacity_provider_name    = module.ecs_capacity_provider.capacity_provider_name
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  security_group_id         = module.ecs_node_sg.security_group_id
  log_group_arn             = module.log_group.cloudwatch_log_group_arn
  cloudwatch_log_group_name = module.log_group.cloudwatch_log_group_name
  alb_listener_arn          = module.alb.listener_arn
  alb_dns_name = module.alb.alb_dns_name


  depends_on = [
    module.ecs_capacity_provider,
    module.ecs_cluster,
    module.alb,
    module.ecs_asg
  ]
}

# Add a null_resource to wait for tasks to be running and output their info


resource "null_resource" "check_task_status" {
  depends_on = [module.ecs_service]
  
  triggers = {
    service_id = module.ecs_service.service_id
  }
  
  provisioner "local-exec" {
    environment = {
      CLUSTER_NAME     = module.ecs_cluster.cluster_name
      SERVICE_NAME     = module.ecs_service.service_name
      TIMESTAMP        = formatdate("YYYYMMDDhhmmss", timestamp())
      LOG_FILE_PATH    = "${path.module}/ecs_deployment_logs/ecs_deployment_${formatdate("YYYYMMDDhhmmss", timestamp())}.log"
    }

    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
# Create logs directory if it doesn't exist
mkdir -p "${path.module}/ecs_deployment_logs"

# Redirect all output to the log file
{
echo "=== ECS Deployment Insights ==="
echo "Timestamp: $TIMESTAMP"
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo "Log File: $LOG_FILE_PATH"
echo "==============================="

# 1. Basic Service Status
echo -e "\n--- Service Overview ---"
aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --query 'services[0].{status:status, runningCount:runningCount, desiredCount:desiredCount, pendingCount:pendingCount, events:events[0].message}' \
  --output json

# 2. List Tasks in the Service
echo -e "\n--- Tasks in Service ---"
aws ecs list-tasks \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --output json

# 3. Detailed Task Information
echo -e "\n--- Detailed Task Descriptions ---"
TASKS=$(aws ecs list-tasks \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --query 'taskArns' \
  --output text)

if [ -n "$TASKS" ]; then
  aws ecs describe-tasks \
    --cluster "$CLUSTER_NAME" \
    --tasks $TASKS \
    --query 'tasks[].{
      TaskArn: taskArn, 
      LastStatus: lastStatus, 
      DesiredStatus: desiredStatus, 
      Health: healthStatus,
      StartedAt: startedAt,
      Containers: containers[].{
        Name: name, 
        Image: image, 
        LastStatus: lastStatus, 
        HealthStatus: healthStatus
      }
    }' \
    --output json
fi

# 4. Task Definition Details
echo -e "\n--- Current Task Definition ---"
TASK_DEF=$(aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --query 'services[0].taskDefinition' \
  --output text)

aws ecs describe-task-definition \
  --task-definition "$TASK_DEF" \
  --query '{
    Family: family,
    Revision: revision,
    ContainerDefinitions: containerDefinitions[].{
      Name: name,
      Image: image,
      CPU: cpu,
      Memory: memory
    }
  }' \
  --output json

# 5. Deployment Configuration
echo -e "\n--- Deployment Details ---"
aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --query 'services[0].deployments[*].{
    Status: status, 
    DesiredCount: desiredCount, 
    RunningCount: runningCount, 
    PendingCount: pendingCount,
    CreatedAt: createdAt
  }' \
  --output json

# Always continue deployment
exit 0
} > "$LOG_FILE_PATH"
EOF
  }
}



# 16. ECS Service auto_scaling  ----------------------- 
module "ecs_service_auto_scaling" {
  source  = "./modules/ecs_service_auto_scaling"
  asg_arn = module.ecs_asg.asg_arn

  cluster_name        = module.ecs_cluster.cluster_name
  service_name        = module.ecs_service.service_name
  min_capacity        = 1
  max_capacity        = 5
  target_cpu_value    = 80
  target_memory_value = 80

  depends_on = [module.ecs_service]

}

# Detect if we're running terraform destroy
locals {
  is_destroy = terraform.workspace == "default" && length(terraform.workspace) == 0
}

module "destroy" {
  source = "./modules/destroy"
  
  cluster_name = module.ecs_cluster.cluster_name
  service_name = module.ecs_service.service_name
  asg_name     = module.ecs_asg.asg_name
  task_family  = module.ecs_task_definition.family

  depends_on = [
    module.ecs_service_auto_scaling,
    module.ecs_service,
    module.ecs_capacity_provider,
    module.ecs_asg,
    module.alb,
    module.nat_gateway,
    module.route_table
  ]
}