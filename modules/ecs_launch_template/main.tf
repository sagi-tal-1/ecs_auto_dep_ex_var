resource "aws_launch_template" "ecs_ec2" {
  name_prefix   = var.name_prefix
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  
  }

  iam_instance_profile {
    arn = var.iam_instance_profile_arn
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
    echo ECS_AVAILABLE_LOGGING_DRIVERS='["json-file","awslogs"]' >> /etc/ecs/ecs.config
    yum install -y awslogs
    systemctl enable awslogsd.service
    systemctl start awslogsd.service
  EOF
  )
}
