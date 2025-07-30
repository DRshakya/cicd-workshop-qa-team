#!/bin/bash
set -e	
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"


branch_name="${GITHUB_REF#refs/heads/}"

cd backend
docker build -t "$ECR_REGISTRY/$ECR_REPOSITORY:$branch_name-latest" .


docker push "$ECR_REGISTRY/$ECR_REPOSITORY:$branch_name-latest"


aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --targets "[{\"Key\":\"InstanceIds\",\"Values\":[\"$EC2_INSTANCE_ID\"]}]" \
    --parameters "{\"commands\":[\"sudo su - root -c '/root/deployment/deployment_script_teamN-name.sh'\"]}" \
    --region "$AWS_REGION"
