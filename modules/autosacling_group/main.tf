
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = false
  
  launch_template {
  id      = var.launch_template_id
  version = "$Latest"
}

  tag {
    key                 = "Name"
    value               = var.instance_name
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
  
}
