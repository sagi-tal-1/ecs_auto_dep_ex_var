# modules/ecs_node_role/main.tf

# Base assume role policy document
data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

# permissions policy document
data "aws_iam_policy_document" "ecs_node_permissions" {
  statement {
    effect = "Allow"
    actions = [
      # IAM Permissions
      "iam:PassRole",
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      
      # EC2 Permissions
      "ec2:DescribeAddresses",
      "ec2:ReleaseAddress",
      "ec2:DisassociateAddress",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVolumes",
      "ec2:CreateTags",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      
      # ECS Permissions
      "ecs:RegisterContainerInstance",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Submit*",
      "ecs:Poll",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:ListTasks",
      "ecs:ListContainerInstances",
      "ecs:DescribeContainerInstances",
      "ecs:UpdateContainerAgent",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:RunTask",
      "ecs:DescribeTasks",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:DescribeClusters",
      "ecs:ListClusters",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:ListTaskDefinitions",
      
      # ECR Permissions
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      
      # CloudWatch Logs Permissions
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      
      # Systems Manager Permissions (Enhanced)
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:UpdateInstanceInformation",
      "ssm:DescribeParameters",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:DeleteParameters",
      "ssm:AddTagsToResource",
      "ssm:RemoveTagsFromResource",
      "ssm:ListTagsForResource",
      "ssm:GetParameterHistory",
      "ssm:LabelParameterVersion",
      "ssm:GetServiceSetting",
      "ssm:UpdateServiceSetting",
      "ssm:ResetServiceSetting",
      "ssm:StartSession",
      "ssm:TerminateSession",
      "ssm:ResumeSession",
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus",
      "ssm:DescribeInstanceInformation",
      "ssm:DescribeInstanceProperties",
      "ssm:DescribeInstanceAssociations",
      "ssm:GetDocument",
      "ssm:ListDocuments",
      "ssm:ListDocumentVersions",
      "ssm:DescribeDocument",
      "ssm:DescribeDocumentParameters",
      "ssm:DescribeInstancePatches",
      "ssm:DescribeInstancePatchStates",
      "ssm:DescribePatchBaselines",
      "ssm:GetDefaultPatchBaseline",
      "ssm:GetPatchBaseline",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:CreateAssociation",
      "ssm:DeleteAssociation",
      "ssm:UpdateAssociation",
      "ssm:ListCommandInvocations",
      "ssm:ListCommands",
      "ssm:SendCommand",
      "ssm:GetCommandInvocation",
      "ssm:CancelCommand",
      "ssm:CreateActivation",
      "ssm:DeleteActivation",
      "ssm:GetActivations",
      "ssm:UpdateManagedInstanceRole",
      
      # SSM Session Manager Permissions
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      
      # Service Discovery Permissions
      "servicediscovery:DiscoverInstances",
      
      # KMS Permissions
      "kms:Decrypt",
      "kms:GenerateDataKey",
      
      # Secrets Manager Permissions
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"]
  }
}

# Create the IAM roles
resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = substr(var.role_name_prefix, 0, 32)
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
  
  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "ecs_exec_role" {
  name_prefix        = "${var.role_name_prefix}-exec"
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

  tags = var.tags
  force_detach_policies = true
}

# Create instance profile
resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = var.profile_name_prefix
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}

# Create the combined permissions policy
resource "aws_iam_policy" "ecs_combined_permissions" {
  name_prefix = substr("${var.role_name_prefix}-combined", 0, 32)
  path        = "/"
  description = "Combined permissions for ECS node and execution roles"
  policy      = data.aws_iam_policy_document.ecs_node_permissions.json
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach CloudWatch policies
resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_cloudwatch_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Attach the combined permissions policy to both roles
resource "aws_iam_role_policy_attachment" "ecs_node_combined_permissions" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = aws_iam_policy.ecs_combined_permissions.arn
}

resource "aws_iam_role_policy_attachment" "ecs_exec_combined_permissions" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = aws_iam_policy.ecs_combined_permissions.arn
}