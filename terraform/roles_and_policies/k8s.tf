resource "aws_iam_policy" "k8s_secret_manager_role_policy" {
  name        = "k8s_secret_manager_role_policy"
  description = "Policy that allows access to k8s secret"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid     = "VisualEditor0"
        Effect  = "Allow"
        Action  = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:k8s/*"
      }
    ]
  })
}

resource "aws_iam_role" "k8s_secret_manager_role" {
  name               = "k8s_secret_manager_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect  = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"  # EC2 instances will assume this role
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "k8s_secret_manager_role_policy_attachment" {
  role       = aws_iam_role.k8s_secret_manager_role.name
  policy_arn = aws_iam_policy.k8s_secret_manager_role_policy.arn
}

# Create an instance profile, from the desired IAM Role, to be attached to the EC2 instance
# A name of the IAM instance profile
# The IAM role being associated with the instance profile
resource "aws_iam_instance_profile" "k8s_instance_profile" {
  name = "k8s_instance_profile"
  role = aws_iam_role.k8s_secret_manager_role.name
}

# Output the IAM Instance Profile name to pass to the k8s module
output "k8s_instance_profile" {
  value = aws_iam_instance_profile.k8s_instance_profile.name
}
