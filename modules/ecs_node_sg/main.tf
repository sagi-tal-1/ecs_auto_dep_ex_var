resource "aws_security_group" "ecs_node_sg" {
  name_prefix = var.name_prefix
  description = "Security group for ECS nodes"
  vpc_id      = var.vpc_id
  revoke_rules_on_delete = false

  
  # Allow all inbound traffic from ALB
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow all inbound traffic from ALB"
  }

  # Allow SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from anywhere"
  }

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # Allow ICMP from anywhere
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ICMP from anywhere"
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
    Name = "${var.name_prefix}-sg"
  }
}

# Allow all traffic from the VPC CIDR
resource "aws_security_group_rule" "allow_all_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.ecs_node_sg.id
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group_rule" "allow_container_ports" {
     type              = "ingress"
     from_port         = 0
     to_port           = 65535
     protocol          = "tcp"
     cidr_blocks       = ["0.0.0.0/0"]
     security_group_id = aws_security_group.ecs_node_sg.id
     description       = "Allow inbound traffic on container ports"
   }

