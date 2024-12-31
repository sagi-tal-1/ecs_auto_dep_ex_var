# moduls/autoscaling_group/main.tf
# Existing ASG for ECS Tasks in AZ-A
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = var.az_a_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  # capacity rebalancing for better availability
  capacity_rebalance = true

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  health_check_grace_period = 10
  health_check_type         = "EC2"
  protect_from_scale_in     = true

  lifecycle {
    create_before_destroy = false
    ignore_changes        = [desired_capacity, target_group_arns]
  }

  dynamic "tag" {
    for_each = {
      Name             = var.instance_name
      AmazonECSManaged = "true"
      Purpose          = "ECS"
      Zone            = "us-east-1a"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  initial_lifecycle_hook {
    name                 = "terminate_hook"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
  }
}

# New ASG for Load Balancer in AZ-B
resource "aws_autoscaling_group" "lb" {
  name                = "${var.name_prefix}-asg-lb"
  vpc_zone_identifier = var.az_b_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  # capacity rebalancing for better availability
  capacity_rebalance = true
 

  # instance refresh for rolling updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  health_check_grace_period = 10
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  lifecycle {
    create_before_destroy = false
    ignore_changes        = [desired_capacity, target_group_arns]
  }

  initial_lifecycle_hook {
    name                 = "terminate_hook"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
  }
dynamic "tag" {
    for_each = {
      Name             = "${var.instance_name}-lb"
      AmazonECSManaged = "false"
      Purpose          = "LoadBalancer"
      Zone            = "us-east-1b"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }



}

# Data source to query the ECS ASG
data "aws_autoscaling_group" "ecs" {
  name = aws_autoscaling_group.ecs.name
  depends_on = [aws_autoscaling_group.ecs]
}

# Data source to query the Load Balancer ASG
data "aws_autoscaling_group" "lb" {
  name = aws_autoscaling_group.lb.name
  depends_on = [aws_autoscaling_group.lb]
}

# Data source to get the instance IDs for ECS
data "aws_instances" "ecs" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [data.aws_autoscaling_group.ecs.name]
  }
}

# Data source to get the instance IDs for Load Balancer
data "aws_instances" "lb" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [data.aws_autoscaling_group.lb.name]
  }
}

















# resource "aws_autoscaling_group" "ecs" {
#   name                = "${var.name_prefix}-asg"
#   vpc_zone_identifier = var.subnet_ids
#   min_size           = var.min_size
#   max_size           = var.max_size
#   desired_capacity   = var.desired_capacity
  
#   # capacity rebalancing for better availability
#   capacity_rebalance = true

#   # instance refresh for rolling updates
#   instance_refresh {
#     strategy = "Rolling"
#     preferences {
#       min_healthy_percentage = 50
#       instance_warmup = 300
#     }
#   }


#   launch_template {
#     id      = var.launch_template_id
#     version = "$Latest"
#   }

#   health_check_grace_period = 10
#   health_check_type        = "EC2"
#   protect_from_scale_in    = false

#   lifecycle {
#     create_before_destroy = false
#     ignore_changes       = [desired_capacity, target_group_arns]
#   }

#   dynamic "tag" {
#     for_each = {
#       Name             = var.instance_name
#       AmazonECSManaged = "true"
#     }
#     content {
#       key                 = tag.key
#       value              = tag.value
#       propagate_at_launch = true
#     }
#   }

#   initial_lifecycle_hook {
#     name                   = "terminate_hook"
#     lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
#     default_result        = "CONTINUE"
#     heartbeat_timeout     = 300
#   }
# } 

# # Data source to query the ASG
# data "aws_autoscaling_group" "ecs" {
#   name = aws_autoscaling_group.ecs.name
# }

# # Data source to get the instance IDs
# data "aws_instances" "ecs" {
#   filter {
#     name   = "tag:aws:autoscaling:groupName"
#     values = [data.aws_autoscaling_group.ecs.name]
#   }
# }