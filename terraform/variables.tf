variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, tst, prd)"
  type        = string
  validation {
    condition     = contains(["dev", "tst", "prd"], var.environment)
    error_message = "Environment must be one of: dev, tst, prd."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "sagemaker_image_uri" {
  description = "URI of the SageMaker container image"
  type        = string
  default     = "763104351884.dkr.ecr.ap-southeast-2.amazonaws.com/huggingface-pytorch-inference:1.13.1-transformers4.26.0-cpu-py39-ubuntu20.04"
}

variable "embedding_model_name" {
  description = "Name of the HuggingFace model to use"
  type        = string
  default     = "sentence-transformers/all-MiniLM-L6-v2"
}

variable "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint"
  type        = string
}

variable "lambda_artifacts_bucket_name" {
  description = "S3 bucket name that stores Lambda deployment packages"
  type        = string
  default     = "zackshioi-agent-lambda-artifacts"
}

variable "lambda_package_s3_key" {
  description = "S3 key for the Lambda deployment package zip"
  type        = string
  default     = "ingest/lambda_function.zip"
}

variable "lambda_package_s3_object_version" {
  description = "Optional S3 object version for the Lambda deployment package"
  type        = string
  default     = null
}

variable "openai_api_key" {
  description = "OpenAI API key for the researcher agent"
  type        = string
  sensitive   = true
}

variable "agent_api_endpoint" {
  description = "Agent API endpoint from Part ingestion"
  type        = string
}

variable "agent_api_key" {
  description = "Agent API key from Part igestion"
  type        = string
  sensitive   = true
}
