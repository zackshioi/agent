output "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint"
  value       = aws_sagemaker_endpoint.embedding_endpoint.name
}

output "sagemaker_endpoint_arn" {
  description = "ARN of the SageMaker endpoint"
  value       = aws_sagemaker_endpoint.embedding_endpoint.arn
}

output "vector_bucket_name" {
  description = "Name of the S3 Vectors bucket"
  value       = aws_s3_bucket.vectors.id
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_api_gateway_stage.api.invoke_url}/ingest"
}

output "api_key_id" {
  description = "API Key ID"
  value       = aws_api_gateway_api_key.api_key.id
}

output "api_key_value" {
  description = "API Key value (sensitive)"
  value       = aws_api_gateway_api_key.api_key.value
  sensitive   = true
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.researcher.repository_url
}

# output "app_runner_service_url" {
#   description = "URL of the App Runner service"
#   value       = "Not created yet - enable aws_apprunner_service.researcher and apply Terraform first"
# }

# output "app_runner_service_id" {
#   description = "ID of the App Runner service"
#   value       = "Not created yet - enable aws_apprunner_service.researcher and apply Terraform first"
# }

output "setup_instructions" {
  description = "Instructions for setting up environment variables"
  value = <<-EOT
    
    ✅ Ingestion pipeline deployed successfully!
    
    Add the following to your .env file:
    SAGEMAKER_ENDPOINT=${aws_sagemaker_endpoint.embedding_endpoint.name}
    SAGEMAKER_ENDPOINT_ARN=${aws_sagemaker_endpoint.embedding_endpoint.arn}
    VECTOR_BUCKET=${aws_s3_bucket.vectors.id}
    AGENT_API_ENDPOINT=${aws_api_gateway_stage.api.invoke_url}/ingest
    
    To get your API key value:
    aws apigateway get-api-key --api-key ${aws_api_gateway_api_key.api_key.id} --include-value --query 'value' --output text
    
    Then add to .env:
    AGENT_API_KEY=<the-api-key-value>
    
    Test the API:
    curl -X POST ${aws_api_gateway_stage.api.invoke_url}/ingest \
      -H "x-api-key: <your-api-key>" \
      -H "Content-Type: application/json" \
      -d '{"content": "Test document", "metadata": {"source": "test"}}'

    Service URL: Not created yet - enable aws_apprunner_service.researcher and apply Terraform first
    
    Test the researcher:
    curl <app-runner-service-url>/research
  EOT
}
