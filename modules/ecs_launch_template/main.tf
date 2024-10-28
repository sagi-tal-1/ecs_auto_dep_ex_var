#moduls/ecs_launch_template/main.tf
data "aws_region" "current" {}

resource "aws_launch_template" "ecs_ec2" {
  name_prefix   = var.name_prefix
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

   network_interfaces {
    # Specify the public subnet ID directly
    subnet_id = var.public_subnet_ids[0]  # Use the first public subnet from the variable
    associate_public_ip_address = true                   # Ensure EC2 instances receive a public IP
    security_groups             = [var.security_group_id]
  }

  iam_instance_profile {
    arn = var.iam_instance_profile_arn
  }

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    cluster_name    = var.cluster_name
    log_group_name  = var.log_group_name
    log_stream_name = var.log_stream_name
    region          = data.aws_region.current.name
    dockerhub_username = var.dockerhub_username
    dockerhub_password = var.dockerhub_password
    LOG_FILE           = var.log_file
    ERROR_LOG          = var.error_log
 
  }))
}