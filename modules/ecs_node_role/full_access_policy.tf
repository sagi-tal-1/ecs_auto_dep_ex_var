#modules/ecs_node_role/full_access_policy.tf

data "aws_iam_policy_document" "full_access" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "ecs:*",
      "logs:*",
      "iam:PassRole",
      "iam:GetRole",
      "iam:ListRolePolicies",
      "ssm:*",
      "ecr:*",
      "iam:ListAttachedRolePolicies"
      
    ]
    resources = ["*"]
  }
    statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAddresses",
      "ec2:ReleaseAddress"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "full_access" {
  name_prefix  = substr("${var.role_name_prefix}-full", 0, 32)
  path        = "/"
  description = "Full access policy"
  policy      = data.aws_iam_policy_document.full_access.json
}

# Attach full access policy to ECS node role
resource "aws_iam_role_policy_attachment" "full_access_node" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = aws_iam_policy.full_access.arn
}

# Attach full access policy to ECS execution role
resource "aws_iam_role_policy_attachment" "full_access_exec" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = aws_iam_policy.full_access.arn
}

####

data "aws_iam_policy_document" "ecs_node_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssm:ListInstanceAssociations",
      "ssm:DescribeInstanceProperties",
      "ssm:DescribeDocumentParameters",
      "ssm:StartSession",
      "ssm:TerminateSession",
      "ssm:ResumeSession"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  # Include other necessary permissions for your ECS node role
  statement {
  effect = "Allow"
  actions = [
    "ec2messages:AcknowledgeMessage",
    "ec2messages:DeleteMessage",
    "ec2messages:FailMessage",
    "ec2messages:GetEndpoint",
    "ec2messages:GetMessages",
    "ec2messages:SendReply"
  ]
  resources = ["*"]
}

}


