#!/bin/bash

export AWS_DEFAULT_REGION=us-east-1

# ========================================
# Comprehensive Removal Script
# Dismantles EKS setup, Kubernetes
# resources, ECR repos, and 
# associated Terraform files and security groups.
# ========================================

# ----------------------------------------
# Step 1: Remove Kubernetes Resources
# Mute output for stress.yaml
# flask-app.yaml might be absent; issue alert if removal unsuccessful
# ----------------------------------------

kubectl delete -f flask-app.yaml || {
    echo "WARNING: Failed to delete Kubernetes deployment. It may not exist."
}

kubectl delete -f payments.yaml || {
    echo "WARNING: Failed to delete Kubernetes deployment. It may not exist."
}

# ----------------------------------------
# Step 2: Dismantle EKS Terraform Setup
# ----------------------------------------
cd "eks" || { echo "ERROR: Failed to change directory to eks. Exiting."; exit 1; }
echo "NOTE: Destroying EKS cluster."

# Set up Terraform if initialization hasn't occurred
if [ ! -d ".terraform" ]; then
    terraform init
fi

# Execute Terraform destruction to eliminate the EKS cluster
echo "NOTE: Deleting nginx_ingress."
terraform destroy -target=helm_release.nginx_ingress  -auto-approve > /dev/null 2> /dev/null
terraform destroy -auto-approve || { echo "ERROR: Terraform destroy failed. Exiting."; exit 1; }

# Eliminate local Terraform files and cache
rm -rf terraform* .terraform*

cd ..  # Go back to main folder

# ----------------------------------------
# Step 3: Eliminate Residual Security Groups Labeled "k8s*"
# AWS may retain unused security groups post-EKS removal
# ----------------------------------------

# Retrieve AWS security group IDs with names beginning with "k8s"
group_ids=$(aws ec2 describe-security-groups \
  --query "SecurityGroups[?starts_with(GroupName, 'k8s')].GroupId" \
  --output text)

# Skip removal if no relevant groups are detected
if [ -z "$group_ids" ]; then
  echo "NOTE: No security groups starting with 'k8s' found."
fi

# Process each security group ID for removal
for group_id in $group_ids; do
  echo "NOTE: Deleting security group: $group_id"
  aws ec2 delete-security-group --group-id "$group_id"

  # Verify removal outcome and record appropriately
  if [ $? -eq 0 ]; then
    echo "NOTE: Successfully deleted $group_id"
  else
    echo "WARNING: Failed to delete $group_id — possibly still in use by another resource"
  fi
done

# ----------------------------------------
# Step 4: Remove ECR Repositories and Associated Images
# Completely eradicates container image storage
# ----------------------------------------
echo "NOTE: Deleting ECR repository contents."

# Eliminate Flask application ECR repo forcibly, including all images
ECR_REPOSITORY_NAME="flask-stock-app"
aws ecr delete-repository --repository-name "$ECR_REPOSITORY_NAME" --force || {
    echo "WARNING: Failed to delete ECR repository. It may not exist."
}

# Eliminate Flask application ECR repo forcibly, including all images
ECR_REPOSITORY_NAME="flask-payment-app"
aws ecr delete-repository --repository-name "$ECR_REPOSITORY_NAME" --force || {
    echo "WARNING: Failed to delete ECR repository. It may not exist."
}


# ----------------------------------------
# Step 5: Dismantle ECR Terraform Resources
# ----------------------------------------
cd "ecr" || { echo "ERROR: Failed to change directory to ecr. Exiting."; exit 1; }

# Remove ECR Terraform components (repos, policies)
terraform destroy -auto-approve || { echo "ERROR: Terraform destroy failed. Exiting."; exit 1; }

# Clear local Terraform files and caches
rm -rf terraform* .terraform*
cd ..

# ----------------------------------------
# Step 6: All Cleanup Done
# ----------------------------------------
echo "NOTE: Cleanup process completed successfully."
