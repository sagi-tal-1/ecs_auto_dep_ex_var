# moduls/alb/main.tf
# moduls/alb/main.tf
resource "aws_security_group" "http" {
  name_prefix = "http-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [80, 443]
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
# Security Group for NGINX in ECS
resource "aws_security_group" "nginx_ecs" {
  name_prefix = "nginx-ecs-sg-"
  description = "Security group for NGINX ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.http.id]  # Allow traffic from ALB
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nginx-ecs-sg-${var.name_prefix}"
  }
}

# Security Group for NodeJS in ECS
resource "aws_security_group" "nodejs_ecs" {
  name_prefix = "nodejs-ecs-sg-"
  description = "Security group for NodeJS ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.nginx_ecs.id]  # Allow traffic only from NGINX
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nodejs-ecs-sg-${var.name_prefix}"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.http.id]
  
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
    # This will force a new random_id when any of these values change
    name_prefix = var.name_prefix
    vpc_id      = var.vpc_id
    port        = var.nginx_port
  }
}

# Target Group for NGINX Service
resource "aws_lb_target_group" "app" {
  name        = substr("tg-${var.name_prefix}-${random_id.target_group_suffix.hex}", 0, 32)
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
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200,301,302"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  # Add a small delay to ensure unique names
  provisioner "local-exec" {
    command = "sleep 2"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Target Group for NodeJS
resource "aws_lb_target_group" "nodejs" {
  name        = substr("tg-nodejs-${var.name_prefix}-${random_id.target_group_suffix.hex}", 0, 32)
  port        = var.nodejs_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.nodejs_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }

  tags = {
    Name = "nodejs-tg-${var.name_prefix}"
  }
}

resource "aws_lb_listener_rule" "nodejs" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100  # Adjust priority as needed

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nodejs.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]  # path pattern to match  NodeJS 
    }
  }
}






# resource "aws_security_group" "http" {
#   name_prefix = "http-sg-"
#   description = "Allow all HTTP/HTTPS traffic from public"
#   vpc_id      = var.vpc_id

#   dynamic "ingress" {
#     for_each = [80, 443]
#     content {
#       protocol    = "tcp"
#       from_port   = ingress.value
#       to_port     = ingress.value
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   egress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "http-sg-${var.name_prefix}"
#   }
# #----------------------------------------------------
# # Security Group for NGINX in ECS
# resource "aws_security_group" "nginx_ecs" {
#   name_prefix = "nginx-ecs-sg-"
#   description = "Security group for NGINX ECS tasks"
#   vpc_id      = var.vpc_id

#   ingress {
#     protocol        = "tcp"
#     from_port       = 80
#     to_port         = 80
#     security_groups = [aws_security_group.http.id]  # Allow traffic from ALB
#   }

#   egress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "nginx-ecs-sg-${var.name_prefix}"
#   }
# }

# # Security Group for NodeJS in ECS
# resource "aws_security_group" "nodejs_ecs" {
#   name_prefix = "nodejs-ecs-sg-"
#   description = "Security group for NodeJS ECS tasks"
#   vpc_id      = var.vpc_id

#   ingress {
#     protocol        = "tcp"
#     from_port       = 3000
#     to_port         = 3000
#     security_groups = [aws_security_group.nginx_ecs.id]  # Allow traffic only from NGINX
#   }

#   egress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "nodejs-ecs-sg-${var.name_prefix}"
#   }
# }

# }
# #---# Application Load Balancer----------------------------------------
# resource "aws_lb" "main" {
#   name               = var.alb_name
#   load_balancer_type = "application"
#   subnets            = var.subnet_ids
#   security_groups    = [aws_security_group.http.id]
  
#   enable_deletion_protection = false

#   timeouts {
#     create = "30m"
#     update = "30m"
#     delete = "30m"
#   }
  
#   tags = {
#     Name = var.alb_name
#   }
# }

# resource "random_id" "target_group_suffix" {
#   byte_length = 2
#   keepers = {
#     # This will force a new random_id when any of these values change
#     name_prefix = var.name_prefix
#     vpc_id      = var.vpc_id
#     port        = var.nginx_port
#   }
# }
# #----# Target Group for NGINX Service (app=nginx) ------------ nginx ---------
# resource "aws_lb_target_group" "app" { #nginx
#   name        = substr("tg-${var.name_prefix}-${random_id.target_group_suffix.hex}", 0, 32)
#   port        = var.nginx_port
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   target_type = "instance"

#   lifecycle {
#     create_before_destroy = true
#     replace_triggered_by = [
#       random_id.target_group_suffix
#     ]
#   }

#   health_check {
#     path                = "/"
#     healthy_threshold   = 2
#     unhealthy_threshold = 10
#     timeout             = 30
#     interval            = 60
#     matcher             = "200,301,302"
#   }

#   stickiness {
#     type            = "lb_cookie"
#     cookie_duration = 86400
#     enabled         = true
#   }

#   # Add a small delay to ensure unique names
#   provisioner "local-exec" {
#     command = "sleep 2"
#   }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
# }

# # Target Group for NodeJS
# resource "aws_lb_target_group" "nodejs" {
#   name        = substr("tg-nodejs-${var.name_prefix}-${random_id.target_group_suffix.hex}", 0, 32)
#   port        = 3000
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   target_type = "instance"

#   health_check {
#     path                = "/health"  # Adjust based on your nodejs health check endpoint
#     healthy_threshold   = 2
#     unhealthy_threshold = 10
#     timeout             = 30
#     interval            = 60
#     matcher             = "200"
#   }

#   tags = {
#     Name = "nodejs-tg-${var.name_prefix}"
#   }
# }




# # # Security Group for NGINX in private subnet
# # resource "aws_security_group" "nginx_private" {
# #   name_prefix = "nginx-private-sg-"
# #   description = "Security group for NGINX in private subnet"
# #   vpc_id      = var.vpc_id

# #   # Allow inbound traffic from ALB
# #   ingress {
# #     protocol        = "tcp"
# #     from_port       = 80
# #     to_port         = 80
# #     security_groups = [aws_security_group.public_http.id]
# #   }

# #   egress {
# #     protocol    = "-1"
# #     from_port   = 0
# #     to_port     = 0
# #     cidr_blocks = ["0.0.0.0/0"]
# #   }

# #   tags = {
# #     Name = "nginx-private-sg-${var.name_prefix}"
# #   }
# # }
# # #----------------- node js #-------------------------------------------

# # # Target Groups for nodejs Services
# # # Target Groups for nodejs Services
# # resource "aws_lb_target_group" "services" {
# #   count       = var.nodejs_service_count
# #   name        = "nodejs-tg-${count.index}"
# #   port        = 3000  # Explicitly set to 3000
# #   protocol    = "HTTP"
# #   vpc_id      = var.vpc_id
# #   target_type = "ip"

# #   lifecycle {
# #     create_before_destroy = true
# #   }
  
# #   health_check {
# #     path                = each.value.health_check_path
# #     healthy_threshold   = 2
# #     unhealthy_threshold = 10
# #     timeout             = 30
# #     interval            = 60
# #     matcher             = "200"
# #   }

# #   tags = merge(
# #     { Name = each.value.name },
# #     lookup(each.value, "tags", {})
# #   )
# # }









# # # Modified Security Group for NodeJS services
# # resource "aws_security_group" "nodejs_private" {
# #   name_prefix = "nodejs-private-sg-"
# #   description = "Security group for NodeJS services in private subnet"
# #   vpc_id      = var.vpc_id

# #   # Allow inbound traffic ONLY from the NGINX security group
# #   ingress {
# #     protocol        = "tcp"
# #     from_port       = 3000
# #     to_port         = 3000
# #     security_groups = [aws_security_group.nginx_private.id]  # Changed from ALB to NGINX
# #   }

# #   egress {
# #     protocol    = "-1"
# #     from_port   = 0
# #     to_port     = 0
# #     cidr_blocks = ["0.0.0.0/0"]
# #   }

# #   tags = {
# #     Name = "nodejs-private-sg-${var.name_prefix}"
# #   }
# # }