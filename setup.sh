#!/bin/bash

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handler function
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
    exit 1
}

# Success message function
success_msg() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Info message function
info_msg() {
    echo -e "${YELLOW}📝 $1${NC}"
}

echo -e "${YELLOW}🔐 Setting up GCP authentication and running Terraform...${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    error_exit "gcloud CLI is not installed. Please install it first."
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    error_exit "Terraform is not installed. Please install it first."
fi

# Create credentials directory if it doesn't exist
mkdir -p ~/.config/gcloud

# Run gcloud auth login
info_msg "Logging in to Google Cloud (browser will open)..."

# Verify credentials were created
if [ ! -f ~/.config/gcloud/application_default_credentials.json ]; then
    if ! gcloud auth application-default login; then
        error_exit "Failed to authenticate with Google Cloud"
    fi
fi

if [ ! -f ~/.config/gcloud/application_default_credentials.json ]; then
    error_exit "Failed to create credentials file"
fi

success_msg "Credentials saved successfully!"

# Initialize Terraform
info_msg "Running 'terraform init'..."
if ! terraform init; then
    error_exit "Terraform init failed. Check your configuration and try again."
fi

success_msg "Terraform init completed!"

# Validate Terraform
info_msg "Running 'terraform validate'..."
if ! terraform validate; then
    error_exit "Terraform validation failed. Check your configuration and try again."
fi

success_msg "Terraform validation completed!"

# Plan Terraform
info_msg "Running 'terraform plan'..."
if ! terraform plan -out=tfplan; then
    error_exit "Terraform plan failed. Check your configuration and try again."
fi

success_msg "Terraform plan completed!"

# Ask for confirmation before applying
echo ""
echo -e "${YELLOW}⚠️  Review the plan above. Do you want to proceed with 'terraform apply'? (yes/no)${NC}"
read -r confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}⏭️  Terraform apply skipped by user${NC}"
    exit 0
fi

# Apply Terraform
info_msg "Running 'terraform apply'..."
if ! terraform apply tfplan; then
    error_exit "Terraform apply failed. Your infrastructure may be in an inconsistent state. Please investigate and retry."
fi

success_msg "Terraform apply completed!"
echo ""
echo -e "${GREEN}🎉 All done! Your Docker instances are being created.${NC}"
echo -e "${GREEN}Run 'terraform output' to see your instance IPs.${NC}"