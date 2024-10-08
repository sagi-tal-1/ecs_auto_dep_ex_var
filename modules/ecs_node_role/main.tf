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
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = var.profile_name_prefix
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}

# ECS Task Execution Role
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

# Attach necessary policies to the execution role
resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach CloudWatch Logs policy to the execution role
resource "aws_iam_role_policy_attachment" "ecs_exec_cloudwatch_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_policy" {
  name        = "${var.role_name_prefix}-ecr-policy"
  path        = "/"
  description = "IAM policy for ECR access"
  policy      = data.aws_iam_policy_document.ecr_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_ecr_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

data "aws_iam_policy_document" "cloudwatch_logs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "${var.role_name_prefix}-cloudwatch-logs-policy"
  path        = "/"
  description = "IAM policy for CloudWatch Logs access"
  policy      = data.aws_iam_policy_document.cloudwatch_logs_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_ssm_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Add this new policy document
data "aws_iam_policy_document" "ec2_full_access" {
  statement {
    effect = "Allow"
    actions = ["ec2:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_full_access" {
  name        = "${var.role_name_prefix}-ec2-full-access"
  path        = "/"
  description = "Full access to EC2"
  policy      = data.aws_iam_policy_document.ec2_full_access.json
}

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = aws_iam_policy.ec2_full_access.arn
}

# Add these policy attachments
resource "aws_iam_role_policy_attachment" "ecs_full_access" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "dynamodb_full_access" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "rds_full_access" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

