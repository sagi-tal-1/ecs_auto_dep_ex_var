resource "aws_security_group" "ecs_node_sg" {
  name_prefix = var.name_prefix
  description = "Security group for ECS nodes"
  vpc_id      = var.vpc_id

  # Allow inbound traffic from ALB
  ingress {
    from_port       = var.nginx_port
    to_port         = var.nginx_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow inbound traffic from ALB"
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
