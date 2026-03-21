# # App Runner service
# resource "aws_apprunner_service" "researcher" {
#   service_name = "agent-researcher"
  
#   source_configuration {
#     auto_deployments_enabled = false
    
#     # Configure authentication for private ECR repository
#     authentication_configuration {
#       access_role_arn = aws_iam_role.app_runner_role.arn
#     }
    
#     image_repository {
#       image_identifier      = "${aws_ecr_repository.researcher.repository_url}:latest"
#       image_configuration {
#         port = "8000"
#         runtime_environment_variables = {
#           OPENAI_API_KEY    = var.openai_api_key
#           AGENT_API_ENDPOINT = var.agent_api_endpoint
#           AGENT_API_KEY      = var.agent_api_key
#         }
#       }
#       image_repository_type = "ECR"
#     }
#   }
  
#   instance_configuration {
#     cpu    = "1 vCPU"
#     memory = "2 GB"
#     instance_role_arn = aws_iam_role.app_runner_instance_role.arn
#   }
  
#   tags = {
#     Project = "agent"
#     Part    = "researcher"
#   }
# }