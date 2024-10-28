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

resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = var.role_name_prefix
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = var.profile_name_prefix
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
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
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_cloudwatch_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

data "aws_iam_policy_document" "ecs_node_additional_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "ec2:DescribeAddresses",
      "ec2:ReleaseAddress",
      "ec2:DisassociateAddress"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "ecs_node_additional_permissions" {
  name        = "${var.role_name_prefix}-additional-permissions"
  path        = "/"
  description = "Additional permissions for ECS node role including EIP management"
  policy      = data.aws_iam_policy_document.ecs_node_additional_permissions.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_additional_permissions" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = aws_iam_policy.ecs_node_additional_permissions.arn
}