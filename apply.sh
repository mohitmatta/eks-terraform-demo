#!/bin/bash

export AWS_DEFAULT_REGION=us-east-1 

# ========================================
# Full Pipeline Deployment Script
# Deploys ECR, builds Docker containers,
# pushes to ECR, provisions EKS, deploys
# containers to EKS, and validates.
# ========================================

# Run an environment check script to ensure all required tools and variables are set
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# ----------------------------------------
# Function to initialize Terraform if needed
# Checks for .terraform dir to avoid re-init
# ----------------------------------------
init_terraform() {
    if [ ! -d ".terraform" ]; then
        terraform init
    fi
}

# ----------------------------------------
# Step 1: Build ECR Repositories with Terraform
# ----------------------------------------
cd "ecr" || { echo "ERROR: Failed to change directory to ecr"; exit 1; }
echo "NOTE: Building ECR Instance."
init_terraform                          # Ensure Terraform is initialized
terraform apply -auto-approve           # Apply ECR infrastructure without prompt
cd ..                                   # Return to root

# ----------------------------------------
# Step 2: Build & Push Docker Images
# ----------------------------------------
cd "flask-stock-app" || { echo "ERROR: Failed to change directory to flask-stock-app"; exit 1; }
echo "NOTE: Building Flask container with Docker."

# Get AWS Account ID dynamically to reference the correct ECR repo
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "ERROR: Failed to retrieve AWS Account ID. Exiting."
    exit 1
fi

# Authenticate Docker to AWS ECR using get-login-password and piping to login command
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com || {
    echo "ERROR: Docker authentication to ECR failed. Exiting."
    exit 1
}

# ----------- Build Flask App ------------
IMAGE_TAG="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/flask-stock-app:stock-app-rc1"
#cd flask-stock-app
docker build -t $IMAGE_TAG . || { echo "ERROR: Docker build failed. Exiting."; exit 1; }
docker push $IMAGE_TAG || { echo "ERROR: Docker push failed. Exiting."; exit 1; }
cd ..


# ----------- Build Payment App ---------
IMAGE_TAG="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/flask-payment-app:payment-app-rc1"
cd payment-app
docker build -t $IMAGE_TAG . || { echo "ERROR: Docker build failed. Exiting."; exit 1; }
docker push $IMAGE_TAG || { echo "ERROR: Docker push failed. Exiting."; exit 1; }
cd ..


# ----------------------------------------
# Step 3: Provision EKS Cluster via Terraform
# ----------------------------------------
cd "eks" || { echo "ERROR: Failed to change directory to eks"; exit 1; }
echo "NOTE: Building EKS instance."
init_terraform
terraform apply -auto-approve

# # ----------------------------------------
# # Step 4: Prepare Kubernetes YAML Manifests
# # Replace placeholder ${account_id} with real AWS Account ID
# # ----------------------------------------

# Replace placeholder in flask-app.yaml template with real AWS account ID
sed -e "s/\${account_id}/$AWS_ACCOUNT_ID/g" -e "s/flask-app:flask-app-rc1/flask-stock-app:stock-app-rc1/g" -e "s|/flask-app/api|/flask-stock-app/api|g" templates/flask-app.yaml.tmpl > ../flask-app.yaml || {
    echo "ERROR: Failed to generate Kubernetes deployment file. Exiting."
    exit 1
}

# Replace placeholder in payments.yaml template with real AWS account ID
sed "s/\${account_id}/$AWS_ACCOUNT_ID/g" templates/payment-app.yaml.tmpl > ../payments.yaml || {
    echo "ERROR: Failed to generate Kubernetes deployment file. Exiting."
    exit 1
}

cd ..  # Return to root

# ----------------------------------------
# Step 5: Configure kubectl to talk to the EKS cluster
# Updates kubeconfig so kubectl can issue commands to EKS
# ----------------------------------------
aws eks update-kubeconfig --name flask-eks-cluster --region us-east-1 || {
    echo "ERROR: Failed to update kubeconfig for EKS. Exiting."
    exit 1
}

# ----------------------------------------
# Step 6: Deploy Flask App to EKS Cluster
# ----------------------------------------
kubectl apply -f flask-app.yaml || {
    echo "ERROR: Failed to deploy to EKS. Exiting."
    exit 1
}



# ----------------------------------------
# Step 7: Deploy Payment Containers to EKS Cluster
# ----------------------------------------
kubectl apply -f payments.yaml || {
    echo "ERROR: Failed to deploy to EKS. Exiting."
    exit 1
}

echo ""
echo "NOTE: Validating Solutions"

# ----------------------------------------
# Step 8: Run Final Validation Script
# Verifies if services are running correctly
# ----------------------------------------
./validate.sh || {
    echo "ERROR: Validation failed. Exiting."
    exit 1
}

echo "NOTE: Deployment completed successfully."
