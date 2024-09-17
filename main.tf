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
  }
}

provider "aws" {
  region     = "us-east-1"
  retry_mode = "standard"
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
  filename        = "${path.module}/ecs-instance-key.pem"
  file_permission = "0600"
}



data "aws_availability_zones" "available" {
  state = "available"

}

# 1. VPC Module
locals {
  azs_count = 2
  azs_names = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source              = "./modules/vpc"
  name                = "demo-vpc-${random_id.unique.hex}"
  name_prefix         = "demo-${random_id.unique.hex}"
  cidr_block          = var.vpc_cidr
  azs_count           = 2
  azs_names           = slice(data.aws_availability_zones.available.names, 0, 2)
  nat_gateway_ids     = [module.nat_gateway.nat_gateway_id]
  internet_gateway_id = module.internet_gateway.internet_gateway_id
  availability_zones = ["a1"]  # Set your desired availability zones here
 
}

# 2. Security Group Modules
module "ecs_node_sg" {
  source                = "./modules/ecs_node_sg"
  name_prefix           = "demo-ecs-sg-${random_id.unique.hex}"
  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.alb.security_group_id
  nginx_port            = module.ecs_task_definition.nginx_port
  node_port             = module.ecs_task_definition.node_port
}

# 3. Internet Gateway Module
module "internet_gateway" {
  source    = "./modules/internet_gateway"
  vpc_id    = module.vpc.vpc_id
  name      = "demo-igw-${random_id.unique.hex}"
  azs_count = local.azs_count
  azs_names = local.azs_names
}

# 4. Route Table Module
module "route_table" {
  source              = "./modules/route_table"
  vpc_id              = module.vpc.vpc_id
  name                = "demo-rt-public-${random_id.unique.hex}"
  internet_gateway_id = module.internet_gateway.internet_gateway_id
  subnet_count        = local.azs_count
  subnet_ids          = module.vpc.public_subnet_ids
  route_table_id      = module.vpc.public_route_table_id
}

# 5. NAT Gateway Module
module "nat_gateway" {
  source            = "./modules/nat_gateway"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = [module.vpc.public_subnet_ids[0]]
  name_prefix       = "demo-${random_id.unique.hex}"
  az_count          = 1
  region            = "us-east-1"
}

# 6. Application Load Balancer (ALB) Module
module "alb" {
  source      = "./modules/alb"
  name_prefix = "demo-alb-${random_id.unique.hex}"
  alb_name    = "demo-alb-${random_id.unique.hex}"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  nginx_port  = module.ecs_task_definition.nginx_port
}

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

# 9. AWS CloudWatch Logs
module "log_group" {
  source            = "./modules/cloudwatch_logs"
  name = "log_group${random_id.unique.hex}"
  name_prefix       = var.cloudwatch_logs_name_prefix
  retention_in_days = var.cloudwatch_logs_retention_days
  log_group_name = module.log_group.cloudwatch_log_group_name
  
}

module "log_stream" {
  source         = "./modules/cloudwatch_logs"
  name = "log_stream${random_id.unique.hex}"
  name_prefix       = var.cloudwatch_logs_name_prefix
  log_group_name = module.log_group.cloudwatch_log_group_name
}


# 10. ECS Cluster Module
module "ecs_cluster" {
  source                 = "./modules/ecs_cluster"
  name_prefix            = "demo-${random_id.unique.hex}"
  cluster_name           = "demo-cluster-${random_id.unique.hex}"
  capacity_provider_name = module.ecs_capacity_provider.capacity_provider_name
  asg_arn                = module.ecs_asg.asg_arn
}

# 11. ECS Capacity Provider Module
module "ecs_capacity_provider" {
  source                 = "./modules/ecs_capacity_provider"
  capacity_provider_name = "demo-capacity-provider-${random_id.unique.hex}"
  asg_arn                = module.ecs_asg.asg_arn
  cluster_name           = module.ecs_cluster.cluster_name
}

# 12. ECS Launch Template Module
module "ecs_launch_template" {
  source                   = "./modules/ecs_launch_template"
  name_prefix              = "demo-ecs-ec2-${random_id.unique.hex}"
  key_name                 = aws_key_pair.generated_key.key_name
  ami_id                   = "ami-05dc81a6311c42a6e"
  instance_type            = "t2.micro"
  security_group_id        = module.ecs_node_sg.security_group_id
  iam_instance_profile_arn = module.ecs_node_role.instance_profile_arn
  cluster_name             = module.ecs_cluster.cluster_name
  log_group_name  = module.log_group.cloudwatch_log_group_name
  log_stream_name      = module.log_group.cloudwatch_log_stream_name
  
}

# 13. Auto Scaling Group Module
module "ecs_asg" {
  source             = "./modules/ecs_asg"
  name_prefix        = "demo-ecs-asg-${random_id.unique.hex}"
  subnet_ids         = module.vpc.public_subnet_ids
  min_size           = 1
  max_size           = 3
  desired_capacity   = 1
  launch_template_id = module.ecs_launch_template.launch_template_id
  instance_name      = "demo-ecs-instance-${random_id.unique.hex}"
}

# 14. ECS Task Definition Module
module "ecs_task_definition" {
  source                = "./modules/ecs_task_definition"
  family                = "nginx-task-${random_id.unique.hex}"
  container_name        = "nginx"
  log_group_name        = module.log_group.cloudwatch_log_group_name
  log_stream_prefix     = "ecs"
  cpu                   = 256
  memory                = 256
  nginx_port            = 80
  node_port             = 3000
  example_env_value     = "example_value"
  task_role_arn         = module.ecs_node_role.role_arn
  execution_role_arn    = module.ecs_node_role.ecs_exec_role_arn
  log_region            = module.vpc.region # or the specific region you want to use for logs
  availability_zones  = module.vpc.availability_zones 
  

  depends_on = [module.log_group, module.log_stream, module.ecs_task_role]
}

# 15. ECS Service Module
module "ecs_service" {
  source                    = "./modules/ecs_service"
  name_prefix               = var.name_prefix
  service_name              = "${var.name_prefix}-ecs-service-${random_id.unique.hex}"    
  cluster_id                = module.ecs_cluster.cluster_id
  ecs_cluster_id            = module.ecs_cluster.ecs_cluster_id
  task_definition_arn       = module.ecs_task_definition.task_definition_arn
  desired_count             = 2
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

  depends_on = [module.log_group, module.log_stream, module.ecs_task_definition, module.ecs_capacity_provider]
}

resource "null_resource" "drain_ecs_cluster" {
  triggers = {
    cluster_name = module.ecs_cluster.cluster_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      aws ecs list-services --cluster ${self.triggers.cluster_name} --output text --query 'serviceArns[]' | \
      xargs -I {} aws ecs update-service --cluster ${self.triggers.cluster_name} --service {} --desired-count 0
      sleep 60
      aws ecs list-container-instances --cluster ${self.triggers.cluster_name} --output text --query 'containerInstanceArns[]' | \
      xargs -I {} aws ecs deregister-container-instance --cluster ${self.triggers.cluster_name} --container-instance {} --force
      sleep 30
    EOF
  }

  depends_on = [module.ecs_service]
}







