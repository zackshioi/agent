# terraform {
#   required_version = ">= 1.5"

#   required_providers {
#     aws = {
#       source = "hashicorp/aws"
#       version = "~> 6.0"
#     }
#   }

#   backend "s3" {}
# }

# provider "aws" {
#   region = var.aws_region
# }

# variable "github_repository" {
#   description = "GitHub repository in format 'owner/repo'"
#   type        = string
# }

# variable "aws_region" {
#   description = "AWS region for resources that require regional ARNs"
#   type        = string
#   default     = "ap-southeast-2"
# }

# data "aws_caller_identity" "current" {}

# # GitHub OIDC Provider
# # Note: If this already exists in your account, you'll need to import it:
# # terraform import aws_iam_openid_connect_provider.github arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
# resource "aws_iam_openid_connect_provider" "github" {
#   url = "https://token.actions.githubusercontent.com"

#   client_id_list = [
#     "sts.amazonaws.com"
#   ]

#   # This thumbprint is from GitHub's documentation.
#   thumbprint_list = [
#     "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
#   ]
# }

# # IAM Role for GitHub Actions
# resource "aws_iam_role" "github_actions" {
#   name = "github-actions-agent-deploy"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.github.arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
#           }
#           StringLike = {
#             "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
#           }
#         }
#       }
#     ]
#   })

#   tags = {
#     Name       = "GitHub Actions Deploy Role"
#     Repository = var.github_repository
#     ManagedBy  = "terraform"
#   }
# }

# # Attach necessary policies
# resource "aws_iam_role_policy_attachment" "github_lambda" {
#   policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
#   role       = aws_iam_role.github_actions.name
# }

# resource "aws_iam_role_policy_attachment" "github_s3" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
#   role       = aws_iam_role.github_actions.name
# }

# resource "aws_iam_role_policy_attachment" "github_apigateway" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
#   role       = aws_iam_role.github_actions.name
# }

# resource "aws_iam_role_policy_attachment" "github_bedrock" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
#   role       = aws_iam_role.github_actions.name
# }

# resource "aws_iam_role_policy_attachment" "github_sagemaker" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
#   role       = aws_iam_role.github_actions.name
# }

# resource "aws_iam_role_policy_attachment" "github_eventbridge" {
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess"
#   role       = aws_iam_role.github_actions.name
# }

# resource "aws_iam_role_policy_attachment" "github_dynamodb" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
#   role       = aws_iam_role.github_actions.name
# }

# # Custom policy for additional permissions
# resource "aws_iam_role_policy" "github_additional" {
#   name = "github-actions-additional"
#   role = aws_iam_role.github_actions.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "iam:CreateRole",
#           "iam:DeleteRole",
#           "iam:AttachRolePolicy",
#           "iam:DetachRolePolicy",
#           "iam:PutRolePolicy",
#           "iam:DeleteRolePolicy",
#           "iam:GetRole",
#           "iam:GetRolePolicy",
#           "iam:GetPolicy",
#           "iam:GetPolicyVersion",
#           "iam:ListPolicies",
#           "iam:ListRolePolicies",
#           "iam:ListAttachedRolePolicies",
#           "iam:ListPolicyVersions",
#           "iam:ListPolicyTags",
#           "iam:UpdateAssumeRolePolicy",
#           "iam:PassRole",
#           "iam:TagRole",
#           "iam:UntagRole",
#           "iam:ListInstanceProfilesForRole",
#           "sts:GetCallerIdentity"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:GetAuthorizationToken"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:CompleteLayerUpload",
#           "ecr:DescribeRepositories",
#           "ecr:InitiateLayerUpload",
#           "ecr:ListTagsForResource",
#           "ecr:PutImage",
#           "ecr:UploadLayerPart"
#         ]
#         Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:ListTagsForResource"
#         ]
#         Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "apprunner:DescribeService",
#           "apprunner:ListServices",
#           "apprunner:UpdateService"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "acm:AddTagsToCertificate",
#           "acm:DeleteCertificate",
#           "acm:DescribeCertificate",
#           "acm:GetCertificate",
#           "acm:ImportCertificate",
#           "acm:ListCertificates",
#           "acm:ListTagsForCertificate",
#           "acm:RemoveTagsFromCertificate",
#           "acm:RequestCertificate",
#           "acm:RenewCertificate",
#           "acm:UpdateCertificateOptions"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "route53:ChangeResourceRecordSets",
#           "route53:GetChange",
#           "route53:GetHostedZone",
#           "route53:ListHostedZones",
#           "route53:ListHostedZonesByName",
#           "route53:ListResourceRecordSets",
#           "route53:ListTagsForResource"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "github_s3_vectors" {
#   policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AgentS3VectorsAccess"
#   role       = aws_iam_role.github_actions.name
# }

# output "github_actions_role_arn" {
#   value = aws_iam_role.github_actions.arn
# }
