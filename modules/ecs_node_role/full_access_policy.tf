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