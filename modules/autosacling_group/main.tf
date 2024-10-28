
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  health_check_grace_period = 10
  health_check_type         = "EC2"
  protect_from_scale_in     = false
  
  
  launch_template {
  id      = var.launch_template_id
  version = "$Latest"
}
 lifecycle {
    create_before_destroy = false
    
    # Add this to prevent errors during destroy
    ignore_changes = [desired_capacity, target_group_arns]

     # Add initial_lifecycle_hook
  initial_lifecycle_hook {
    name                    = "terminate_hook"
    lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
    default_result         = "CONTINUE"
    heartbeat_timeout      = 300
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
