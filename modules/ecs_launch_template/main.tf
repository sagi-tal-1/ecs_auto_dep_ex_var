#moduls/ecs_launch_template/main.tf
data "aws_region" "current" {}

resource "aws_launch_template" "ecs_ec2" {
  name_prefix   = var.name_prefix
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    subnet_id                   = var.public_subnet_ids[0]
    associate_public_ip_address = true
    security_groups            = [var.security_group_id]
  }

  iam_instance_profile {
    arn = var.iam_instance_profile_arn
  }

user_data = base64encode(<<-EOF
        #!/bin/bash
    
    # Wait for cluster to be active
    sleep 15
    
    # Configure ECS Agent
    cat <<'ECSCONFIG' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${var.cluster_name} 
    ECS_ENGINE_AUTH_TYPE=docker
    ECS_LOGLEVEL=debug
    ECS_WARM_POOLS_CHECK=true
    ECS_CONTAINER_METADATA_URI_ENDPOINT=v4
    ECS_DOCKER_API_VERSION=1.44
    ECSCONFIG
    
   
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name       = "${var.name_prefix}-instance"
      ECSCluster = var.cluster_name
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}




# data "aws_region" "current" {}

# resource "aws_launch_template" "ecs_ec2" {
#   name_prefix   = var.name_prefix
#   image_id      = var.ami_id
#   instance_type = var.instance_type
#   key_name      = var.key_name

#   network_interfaces {
#     subnet_id                   = var.public_subnet_ids[0]
#     associate_public_ip_address = true
#     security_groups            = [var.security_group_id]
#   }

#   iam_instance_profile {
#     arn = var.iam_instance_profile_arn
#   }

#   user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
#     cluster_name       = var.cluster_name
#     log_group_name     = var.log_group_name
#     log_stream_name    = var.log_stream_name
#     region            = data.aws_region.current.name
#     dockerhub_username = var.dockerhub_username
#     dockerhub_password = var.dockerhub_password
#   }))

#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "${var.name_prefix}-instance"
#       ECSCluster = var.cluster_name
#     }
#   }

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "optional"
#     http_put_response_hop_limit = 2
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }