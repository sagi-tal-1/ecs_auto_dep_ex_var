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


 #Add NodeJS target group
resource "aws_lb_target_group" "nodejs" {
  name        = substr("tg-nodejs-${var.name_prefix}-${random_id.target_group_suffix.hex}", 0, 32)
  port        = 3000  # Default Node.js port
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
    path                = "/health"  # Adjust based on your Node.js app health check endpoint
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
}

# Add listener rule for Node.js
resource "aws_lb_listener_rule" "nodejs" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nodejs.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]  # Adjust based on your Node.js app path patterns
    }
  }
}
