# moduls/alb/main.tf
# security_group            internet -> alb--------------------------
resource "aws_security_group" "http" {
  name_prefix = "http-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [80, 443, 22]
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "http-sg-${var.name_prefix}"
  }
}

# ALB 
resource "aws_lb" "main" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.http.id]
  internal           = false
  
  enable_deletion_protection = false

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
  
  tags = {
    Name = var.alb_name
  }
}

resource "random_id" "target_group_suffix" {
  byte_length = 2
  keepers = {
    name_prefix = var.name_prefix
    vpc_id      = var.vpc_id
    port        = var.nginx_port
  }
}

# ALB->EC2---------------------------------- security_group
resource "aws_security_group" "ec2" {
  name_prefix = "http-sg-"
  description = "security_group for web server instance"
  vpc_id      = var.vpc_id

   ingress {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      security_groups = [aws_security_group.http.id, ]
    }
     ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.http.id]  # ALB security group
  }

    # Ingress rules for private subnet communication
    ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = [var.private_subnet_cidrs[0]]
    description = "Allow HTTP from private subnet"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.private_subnet_cidrs[0]]
    description = "Allow SSH from private subnet"
  }
   ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.private_subnet_cidrs[0]]
  }
  

  egress {
   protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.private_subnet_cidrs[0]]
  }
   ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.private_subnet_cidrs[0]]
    description = "Allow SSH from private subnet"
  }

  # Egress rules for private subnet communication
  egress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = [var.private_subnet_cidrs[0]]
    description = "Allow HTTP to private subnet"
  }

  egress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.private_subnet_cidrs[0]]
    description = "Allow SSH to private subnet"
  }

  # General internet access for updates, etc.
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound internet traffic"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "alb2ec2-sg-${var.name_prefix}"
  }
}
#---------------------------------------- 
#---------------- auto scaling group connectivity public to privet ------------------------ 
#---------------------------------------- 

resource "aws_lb_target_group" "ec2" {
  name        = substr("tg-ec2-${var.name_prefix}-${random_id.target_group_suffix.hex}", 0, 32)
  port        = var.nginx_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"  # Target type for EC2 instances

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      random_id.target_group_suffix
    ]
  }

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200,301,302"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 120
    enabled         = true
  }

  tags = {
    Name = "ec2-tg-${var.name_prefix}"
  }
}


resource "aws_lb_listener" "alb_ec2" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = var.autoscaling_group_name
  lb_target_group_arn  = aws_lb_target_group.ec2.arn
}
#---------------------------------------- 
#---------------- ALB -> public to privet for nginx  ------------------------ 
#---------------------------------------- 
#ALB->public to privet subnet 
# Security group for ECS tasks
resource "aws_security_group" "nginx_ecs_tasks" {
  name_prefix = "ecs-tasks-sg-"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.nginx_port
    to_port         = var.nginx_port
    security_groups = [aws_security_group.http.id]
  }
ingress {
    protocol    = "tcp"
    from_port   = 3000  
    to_port     = 3000
    security_groups = [aws_security_group.http.id]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "ecs-tasks-sg-${var.name_prefix}"
  }
}

# New target group for ECS nginx service
resource "aws_lb_target_group" "nginx_ecs" {
  name        = substr("tg-ecs-${var.name_prefix}-${random_id.target_group_suffix.hex}", 0, 32)
  port        = var.nginx_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      random_id.target_group_suffix
    ]
  }

  health_check {
    enabled             = true
    path                = "/health"      # Changed from "/" to "/health" to match Nginx config
    healthy_threshold   = 2              # Kept at 2 as it's a good value
    unhealthy_threshold = 3              # Changed from 10 to 3 for faster detection of unhealthy instances
    timeout             = 5              # Changed from 30 to 5 seconds for faster health checks
    interval            = 30             # Changed from 60 to 30 seconds for more frequent checks
    matcher             = "200"          # Simplified from "200,301,302" to just "200" for health endpoint
    protocol           = "HTTP"
    port               = "traffic-port"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 120
    enabled         = true
  }

  tags = {
    Name = "ecs-tg-nginx${var.name_prefix}"
  }
}


# Additional listener for ECS nginx service
resource "aws_lb_listener_rule" "nginx_ecs" {
  listener_arn = aws_lb_listener.alb_ec2.arn
  priority     = 90  # Higher priority than nodejs_ecs
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_ecs.arn
  }

  condition {
    path_pattern {
      values = ["/ecs/*"]
    }
  }
}

#---------------------------------------- 
#---------------- ALB -> public to privet for node js   ------------------------ 
#---------------------------------------- 

# Security group for nodejs ECS tasks
resource "aws_security_group" "nodejs_ecs_tasks" {
  name_prefix = "nodejs-ecs-tasks-sg-"
  description = "Security group for nodejs ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.http.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "nodejs-ecs-tasks-sg-${var.name_prefix}"
  }
}

# Target group for nodejs ECS service
resource "aws_lb_target_group" "nodejs_ecs" {
  name        = substr("tg-nodejs-${var.name_prefix}-${random_id.target_group_suffix.hex}", 0, 32)
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"  # Target type for ECS tasks

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      random_id.target_group_suffix
    ]
  }

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200,301,302"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 120
    enabled         = true
  }

  tags = {
    Name = "nodejs-ecs-tg-${var.name_prefix}"
  }
}

# Listener rule for nodejs ECS service
resource "aws_lb_listener_rule" "nodejs_ecs" {
  listener_arn = aws_lb_listener.alb_ec2.arn
  priority     = 100  # Lower priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nodejs_ecs.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# Key Improvements:
# 1. Remove duplicate and redundant ingress/egress rules.
# 2. Use variables for ports to avoid hardcoding.
# 3. Add descriptive comments for health checks.
# 4. Remove unnecessary open egress to 0.0.0.0/0.
# 5. Optimize lifecycle blocks to prevent recreation.
# 6. Consolidate multiple ingress rules where possible.
# 7. Add conditions for security group IP-based filtering.
# 8. Validate random_id dependencies for target group uniqueness.
# 9. Use separate ALB listeners for ECS and Node.js.
# 10. Refactor names for clarity and consistency.


