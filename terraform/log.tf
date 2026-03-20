# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/agent-ingest"
  retention_in_days = 7
  
  tags = {
    Project = "agent"
    Part    = "ingestion"
  }
}