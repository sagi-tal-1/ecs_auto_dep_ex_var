data "aws_iam_policy_document" "full_access" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "ecs:*",
      "logs:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "full_access" {
  name        = "${var.role_name_prefix}-full-access"
  path        = "/"
  description = "Full access to EC2, ECS, and CloudWatch Logs"
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