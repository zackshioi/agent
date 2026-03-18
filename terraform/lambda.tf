resource "aws_lambda_function" "ingest" {
  function_name = "agent-ingest"
  role          = aws_iam_role.lambda_role.arn

  s3_bucket = aws_s3_bucket.lambda_artifacts.id
  s3_key    = var.lambda_package_s3_key

  s3_object_version = var.lambda_package_s3_object_version

  handler     = "ingest_s3vectors.lambda_handler"
  runtime     = "python3.12"
  timeout     = 60
  memory_size = 512

  environment {
    variables = {
      VECTOR_BUCKET      = aws_s3_bucket.vectors.id
      SAGEMAKER_ENDPOINT = var.sagemaker_endpoint_name
    }
  }

  tags = {
    Project = "agent"
    Part    = "ingestion"
  }
}
