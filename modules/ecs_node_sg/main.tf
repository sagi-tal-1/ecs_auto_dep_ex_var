#moduls/ecs_node_sg/main.tf
# ECS Node Security Group for Private Subnet
resource "aws_security_group" "ecs_node_sg" {
  name_prefix = var.name_prefix
  description = "Security group for ECS nodes in private subnet"
  vpc_id      = var.vpc_id
  revoke_rules_on_delete = false

  # Allow all traffic from ALB security group
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow all inbound traffic from ALB"
  }

  # Allow all internal VPC traffic for service discovery and container communication
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow all internal VPC traffic"
  }

  # Allow container port ranges for ECS tasks
  ingress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow ephemeral ports for ECS tasks"
  }

  # Allow all outbound traffic (needed for NAT Gateway access)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic via NAT Gateway"
  }

  tags = {
    Name = "${var.name_prefix}-ecs-private-sg"
  }
}

# Get VPC information
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Additional security group rules for container-to-container communication
resource "aws_security_group_rule" "container_communication" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_node_sg.id
  security_group_id        = aws_security_group.ecs_node_sg.id
  description              = "Allow container-to-container communication"
}

# Security group for the ALB (should be in public subnet)
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.name_prefix}-alb"
  description = "Security group for ALB in public subnet"
  vpc_id      = var.vpc_id

  # Allow inbound HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP inbound"
  }

  # Allow inbound HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS inbound"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}





# resource "aws_security_group" "ecs_node_sg" {
#   name_prefix = var.name_prefix
#   description = "Security group for ECS nodes"
#   vpc_id      = var.vpc_id
#   revoke_rules_on_delete = false

  
#   # Allow all inbound traffic from ALB
#   ingress {
#     from_port       = 0
#     to_port         = 65535
#     protocol        = "tcp"
#     security_groups = [var.alb_security_group_id]
#     description     = "Allow all inbound traffic from ALB"
#   }

#   # Allow SSH from anywhere
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow SSH from anywhere"
#   }

#   # Allow HTTP from anywhere
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow HTTP from anywhere"
#   }

#   # Allow ICMP from anywhere
#   ingress {
#     from_port   = -1
#     to_port     = -1
#     protocol    = "icmp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow ICMP from anywhere"
#   }

#   # Allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow all outbound traffic"
#   }

#   tags = {
#     Name = "${var.name_prefix}-sg"
#   }
# }

# # Allow all traffic from the VPC CIDR
# resource "aws_security_group_rule" "allow_all_vpc" {
#   type              = "ingress"
#   from_port         = 0
#   to_port           = 65535
#   protocol          = "tcp"
#   cidr_blocks       = [data.aws_vpc.selected.cidr_block]
#   security_group_id = aws_security_group.ecs_node_sg.id
# }

# data "aws_vpc" "selected" {
#   id = var.vpc_id
# }

# resource "aws_security_group_rule" "allow_container_ports" {
#      type              = "ingress"
#      from_port         = 0
#      to_port           = 65535
#      protocol          = "tcp"
#      cidr_blocks       = ["0.0.0.0/0"]
#      security_group_id = aws_security_group.ecs_node_sg.id
#      description       = "Allow inbound traffic on container ports"
#    }

