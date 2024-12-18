# Existing ECS Task Role
# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name_prefix = var.task_role_name_prefix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_stop_task_policy" {
  name = "ecs-stop-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "ecs:StopTask"
        Resource = "arn:aws:ecs:*:*:task/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_service_discovery" {
  name = "ecs-service-discovery-policy"
  role = aws_iam_role.ecs_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:DescribeContainerInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}


# ECS Task Role Policy for Task-Specific Permissions
resource "aws_iam_role_policy" "task_role_policy" {
  name = "ecs-task-role-policy"
   role = aws_iam_role.ecs_task_role.id 

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:DescribeContainerInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
# ECS Task Execution Role
resource "aws_iam_role" "ecs_exec_role" {
  name_prefix = var.exec_role_name_prefix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Task Execution Role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECR Permissions for Execution Role
resource "aws_iam_role_policy" "ecr_policy" {
  name = "ecr_policy"
  role = aws_iam_role.ecs_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}


# ENI Management Permissions for Task Role
resource "aws_iam_role_policy" "ecs_task_role_vpc_policy" {
  name = "ecs_task_vpc_policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ecs:DescribeClusters",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

# S3 policy for task role
resource "aws_iam_role_policy" "task_s3_policy" {
  name = "${var.task_role_name_prefix}-s3-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.nginx_config_bucket_name}/*"
        ]
      }
    ]
  })
}

# CloudWatch policy for task role
resource "aws_iam_role_policy" "task_cloudwatch_policy" {
  name = "task_cloudwatch_policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
# SSM policy for task role
resource "aws_iam_role_policy" "task_ssm_policy" {
  name = "task_ssm_policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# SSM policy attachment for execution role
resource "aws_iam_role_policy_attachment" "ecs_exec_role_ssm_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# Additional permissions for Docker Hub access from private subnet
resource "aws_iam_role_policy" "ecs_task_execution_docker_policy" {
  name = "ecs_task_execution_docker_policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Additional networking permissions for task execution role
resource "aws_iam_role_policy" "ecs_task_execution_network_policy" {
  name = "ecs_task_execution_network_policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# EC2 Instance Profile Role for ECS Container Instances
resource "aws_iam_role" "ecs_instance_role" {
  name_prefix = "ecs-instance-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach required policies for EC2 instances running ECS tasks
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
# Attach SSM Instance Core policy
resource "aws_iam_role_policy_attachment" "ssm_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# If you need custom SSM permissions, create and attach a custom policy
resource "aws_iam_policy" "custom_ssm_policy" {
  name = "CustomSSMInstancePolicy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_ssm_policy_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = aws_iam_policy.custom_ssm_policy.arn
}
# Additional policy for EC2 instances to pull Docker images
resource "aws_iam_role_policy" "ecs_instance_docker_policy" {
  name = "ecs_instance_docker_policy"
  role = aws_iam_role.ecs_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ssm:UpdateInstanceInformation",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:ListInstanceAssociations",
          "ssm:DescribeInstanceProperties",
          "ec2messages:*",
          "ssmmessages:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create instance profile for EC2 instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name_prefix = "ecs-instance-profile-"
  role        = aws_iam_role.ecs_instance_role.name
}






# resource "aws_iam_role" "ecs_task_role" {
#   name_prefix        = "${var.task_role_name_prefix}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Existing ECS Task Execution Role
# resource "aws_iam_role" "ecs_exec_role" {
#   name_prefix        = var.exec_role_name_prefix
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Existing policy attachments
# resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
#   role       = aws_iam_role.ecs_exec_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# # New: VPC Networking Permissions for Execution Role
# resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_vpc" {
#   role       = aws_iam_role.ecs_exec_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# # New: ECR Permissions for Execution Role
# resource "aws_iam_role_policy" "ecr_policy" {
#   name = "ecr_policy"
#   role = aws_iam_role.ecs_exec_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # New: ENI Management Permissions for Task Role
# resource "aws_iam_role_policy" "ecs_task_role_vpc_policy" {
#   name = "ecs_task_vpc_policy"
#   role = aws_iam_role.ecs_task_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:CreateNetworkInterface",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DeleteNetworkInterface",
#           "ec2:DescribeInstances",
#           "ec2:AttachNetworkInterface",
#           "ec2:DetachNetworkInterface"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # Existing task_role resource (previously missing name)
# resource "aws_iam_role" "task_role" {
#   name = "${var.task_role_name_prefix}"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Existing S3 policy for task role
# resource "aws_iam_role_policy" "task_s3_policy" {
#   name = "${var.task_role_name_prefix}-s3-policy"
#   role = aws_iam_role.task_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject"
#         ]
#         Resource = [
#           "arn:aws:s3:::${var.nginx_config_bucket_name}/*"
#         ]
#       }
#     ]
#   })
# }

# # Existing CloudWatch policy for task role
# resource "aws_iam_role_policy" "task_cloudwatch_policy" {
#   name = "task_cloudwatch_policy"
#   role = aws_iam_role.ecs_task_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # Existing SSM policy for task role
# resource "aws_iam_role_policy" "task_ssm_policy" {
#   name = "task_ssm_policy"
#   role = aws_iam_role.ecs_task_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ssm:GetParameters",
#           "ssm:GetParameter",
#           "ssm:GetParametersByPath"
#         ]
#         Resource = "arn:aws:ssm:*:*:parameter/*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ssmmessages:CreateControlChannel",
#           "ssmmessages:CreateDataChannel",
#           "ssmmessages:OpenControlChannel",
#           "ssmmessages:OpenDataChannel"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:DescribeLogGroups"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # Existing SSM policy attachment for execution role
# resource "aws_iam_role_policy_attachment" "ecs_exec_role_ssm_policy" {
#   role       = aws_iam_role.ecs_exec_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
# }

