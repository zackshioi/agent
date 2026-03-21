# SageMaker Model
resource "aws_sagemaker_model" "embedding_model" {
  name               = "agent-embedding-model"
  execution_role_arn = aws_iam_role.sagemaker_role.arn

  primary_container {
    image = var.sagemaker_image_uri
    environment = {
      HF_MODEL_ID = var.embedding_model_name
      HF_TASK     = "feature-extraction"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.sagemaker_full_access]
}

# Serverless Inference Config
resource "aws_sagemaker_endpoint_configuration" "serverless_config" {
  name = "agent-embedding-serverless-config"

  production_variants {
    model_name = aws_sagemaker_model.embedding_model.name
    
    serverless_config {
      memory_size_in_mb = 3072
      max_concurrency   = 2  # Reduced from 10 to avoid quota limit
    }
  }
}

# Add a delay for IAM role propagation before creating endpoint
resource "time_sleep" "wait_for_iam_propagation" {
  depends_on = [
    aws_iam_role_policy_attachment.sagemaker_full_access
  ]
  
  create_duration = "15s"
}

# SageMaker Endpoint
resource "aws_sagemaker_endpoint" "embedding_endpoint" {
  name                 = var.sagemaker_endpoint_name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.serverless_config.name
  
  depends_on = [
    time_sleep.wait_for_iam_propagation
  ]
  
}