# variable "github_repository" {
#   description = "GitHub repository in format 'owner/repo'"
#   type        = string
#   default     = "zackshioi/agent"
# }

# resource "aws_iam_openid_connect_provider" "github" {
#   url = "https://token.actions.githubusercontent.com"

#   client_id_list = [
#     "sts.amazonaws.com",
#   ]

#   thumbprint_list = [
#     "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
#   ]
# }

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
#             "token.actions.githubusercontent.com:sub" = "repo:zackshioi/agent:*"
#           }
#         }
#       },
#     ]
#   })

#   tags = {
#     Name       = "GitHub Actions Deploy Role"
#     Repository = "zackshioi/agent"
#     ManagedBy  = "terraform"
#   }
# }

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

# resource "aws_iam_role_policy_attachment" "github_s3_vectors" {
#   policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AgentS3VectorsAccess"
#   role       = aws_iam_role.github_actions.name
# }

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
#           "sts:GetCallerIdentity",
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "lambda:TagResource",
#           "lambda:UntagResource",
#           "lambda:ListTags",
#         ]
#         Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:DeleteLogGroup",
#           "logs:DescribeLogGroups",
#           "logs:PutRetentionPolicy",
#           "logs:DeleteRetentionPolicy",
#           "logs:TagResource",
#           "logs:UntagResource",
#           "logs:ListTagsForResource",
#         ]
#         Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "apigateway:GET",
#           "apigateway:POST",
#           "apigateway:PUT",
#           "apigateway:PATCH",
#           "apigateway:DELETE",
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
#           "acm:UpdateCertificateOptions",
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
#           "route53:ListTagsForResource",
#         ]
#         Resource = "*"
#       },
#     ]
#   })
# }

# output "github_actions_role_arn" {
#   value = aws_iam_role.github_actions.arn
# }
