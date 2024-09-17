data "aws_region" "current" {}

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
  echo ECS_AVAILABLE_LOGGING_DRIVERS='["awslogs"]' >> /etc/ecs/ecs.config

  # Install CloudWatch Logs agent
  curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
  python awslogs-agent-setup.py --non-interactive --region ${data.aws_region.current.name} --log-group-name ${var.log_group_name} --log-stream-name-prefix ${var.log_stream_name}

  # Start CloudWatch Logs agent
  systemctl start amazon-cloudwatch-agent
EOF
)


}
