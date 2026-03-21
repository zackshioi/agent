# ECR repository for the researcher Docker image
resource "aws_ecr_repository" "researcher" {
  name                 = "agent-researcher"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # Allow deletion even with images
  
  image_scanning_configuration {
    scan_on_push = false
  }
  
  tags = {
    Project = "agent"
    Part    = "researcher"
  }
}