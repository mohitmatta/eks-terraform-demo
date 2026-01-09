# AWS Elastic Container Registry (ECR) for storing Docker container images
# Stores flask_app containers

resource "aws_ecr_repository" "flask_stock_app" {
  name                 = "flask-stock-app"              # ECR repository name
  image_tag_mutability = "MUTABLE"                # Allow overwriting of image tags

  # Enable automatic image scanning for vulnerabilities
  image_scanning_configuration {
    scan_on_push = true                           # Scan images on push
  }
}

resource "aws_ecr_repository" "flask_payment_app" {
  name                 = "flask-payment-app"              # ECR repository name
  image_tag_mutability = "MUTABLE"                # Allow overwriting of image tags

  # Enable automatic image scanning for vulnerabilities
  image_scanning_configuration {
    scan_on_push = true                           # Scan images on push
  }
}
