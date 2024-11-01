resource "aws_autoscaling_group" "ecs" {
  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size           = var.min_size
  max_size           = var.max_size
  desired_capacity   = var.desired_capacity
  
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  health_check_grace_period = 10
  health_check_type        = "EC2"
  protect_from_scale_in    = false

  lifecycle {
    create_before_destroy = false
    ignore_changes       = [desired_capacity, target_group_arns]
  }

  dynamic "tag" {
    for_each = {
      Name             = var.instance_name
      AmazonECSManaged = "true"
    }
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }

  initial_lifecycle_hook {
    name                   = "terminate_hook"
    lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
    default_result        = "CONTINUE"
    heartbeat_timeout     = 300
  }
} 