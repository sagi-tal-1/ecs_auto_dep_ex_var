
# modules/ecs_task_role/main.tf
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

resource "aws_iam_role_policy" "ecs_service_discoveryv1" {
  name = "ecs-service-discovery-policy"
  role = aws_iam_role.ecs_exec_role.id  

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
resource "aws_iam_role_policy" "ecs_task_execution_docker_policy_v2" {
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

# ECS Task Metadata Endpoint Policy
resource "aws_iam_role_policy" "ecs_task_metadata_policy" {
  name = "ecs-task-metadata-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeClusters",
          "ecs:ListContainerInstances",
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*"
      }
    ]
  })
}

# EC2 Instance Metadata and Tags Policy
resource "aws_iam_role_policy" "ec2_metadata_policy" {
  name = "ec2-metadata-policy"
  role = aws_iam_role.ecs_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceStatus",
          "ecs:ListAttributes",
          "ecs:GetAttributes",
          "ecs:ListTaskDefinitionFamilies",
          "ecs:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# Enhanced Monitoring Policy
resource "aws_iam_role_policy" "enhanced_monitoring_policy" {
  name = "enhanced-monitoring-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}


# Add this new policy attachment for the execution role
resource "aws_iam_role_policy" "ecs_exec_additional_permissions" {
  name = "ecs-exec-additional-permissions"
  role = aws_iam_role.ecs_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:ListClusters",
          "ecs:DescribeClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Add this new policy for the EC2 instance role
resource "aws_iam_role_policy" "ecs_instance_additional_permissions" {
  name = "ecs-instance-additional-permissions"
  role = aws_iam_role.ecs_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:ListClusters",
          "ecs:DescribeClusters",
          "ecs:DescribeContainerInstances",
          "ec2:DescribeInstances" 
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_exec_discovery_permissions" {
  name = "ecs-exec-discovery-permissions"
  role = aws_iam_role.ecs_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeContainerInstances",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
# ECS Service Discovery Permissions for Task Role
resource "aws_iam_role_policy" "ecs_service_discoveryv2" {
  name = "ecs-service-discovery-policy"
  role = aws_iam_role.ecs_exec_role.id  

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
          "ec2:DescribeInstances",
          "ecs:DiscoverInstances"  # Added container discovery permission
        ]
        Resource = "*"
      }
    ]
  })
}

# Docker API Permissions for Task Role (Added Docker API permissions)
resource "aws_iam_role_policy" "ecs_task_execution_docker_policy_v1" {
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
          "logs:PutLogEvents",
          "ecs:ExecuteCommand",  # Added Docker API permission for task execution
          "ecs:RunTask",         # Added Docker API permission for running tasks
          "ecs:StopTask"         # Added Docker API permission for stopping tasks
        ]
        Resource = "*"
      }
    ]
  })
}

# Filesystem Write Permissions (for EFS or other file systems)
resource "aws_iam_role_policy" "task_filesystem_write_policy" {
  name = "task-filesystem-write-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "efs:WriteFile",
          "efs:WriteData",  # Filesystem write permissions for EFS
          "efs:CreateFileSystem" # Permission to create filesystems if needed
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy" "container_discovery_permissions" {
  name = "container-discovery-permissions"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:DeregisterContainerInstance",
          "ecs:SubmitContainerStateChange",
          "ecs:SubmitTaskStateChange"
        ]
        Resource = "*"
      }
    ]
  })
}

# Add this policy to your ecs_task_role module
resource "aws_iam_role_policy" "ecs_managed_tags_policy" {
  name = "ecs-managed-tags-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ecs:TagResource",
          "ecs:UntagResource",
          "ecs:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# Add this policy to your ecs_exec_role for execution permissions
resource "aws_iam_role_policy" "ecs_exec_tags_policy" {
  name = "ecs-exec-tags-policy"
  role = aws_iam_role.ecs_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ecs:TagResource",
          "ecs:UntagResource",
          "ecs:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
}
#-------------------------------

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

