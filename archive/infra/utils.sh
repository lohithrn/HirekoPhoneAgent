#!/bin/bash

set -e  # Exit on any error
set -x

###########################################
# Print Utilities
###########################################
print_green() {
    tput setaf 2
    echo "$1"
    tput sgr0
}

print_red() {
    tput setaf 1
    echo "$1"
    tput sgr0
}

###########################################
# Docker Utilities
###########################################
check_docker_daemon() {
    if ! docker info > /dev/null 2>&1; then
        print_red "❌ Docker daemon is not running!"
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            print_green "🔄 Attempting to start Docker..."
            sudo systemctl start docker
            sleep 5
            if ! docker info > /dev/null 2>&1; then
                print_red "❌ Failed to start Docker. Please start Docker manually and re-run the script."
                exit 1
            fi
        else
            print_red "⚠️ Please start Docker Desktop and re-run the script."
            exit 1
        fi
    fi
}

###########################################
# AWS Utilities
###########################################
setup_aws() {
    print_green "🔑 Initializing AWS CLI profile '${AWS_PROFILE}'..."
    aws configure list-profiles | grep -q "^${AWS_PROFILE}$" || { 
        print_red "❌ AWS profile '${AWS_PROFILE}' does not exist! Please configure it using: aws configure --profile ${AWS_PROFILE}"
        exit 2
    }

    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text --profile ${AWS_PROFILE})
    if [[ -z "$AWS_ACCOUNT_ID" ]]; then
        print_red "❌ Failed to retrieve AWS account ID. Check your AWS credentials."
        exit 1
    fi
}

setup_ecr() {
    print_green "🔐 Logging in to AWS ECR..."
    aws ecr get-login-password --region $AWS_REGION --profile ${AWS_PROFILE} | \
        docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

    # Convert repository name to lowercase
    local ecr_repo_lower=$(echo "${SERVICE_NAME}/${IMAGE_NAME}" | tr '[:upper:]' '[:lower:]')

    print_green "📦 Checking if ECR repository '${ecr_repo_lower}' exists..."
    if ! aws ecr describe-repositories --repository-names "${ecr_repo_lower}" --region $AWS_REGION --profile ${AWS_PROFILE} > /dev/null 2>&1; then
        print_green "🚀 Creating new ECR repository '${ecr_repo_lower}'..."
        aws ecr create-repository --repository-name "${ecr_repo_lower}" --region $AWS_REGION --profile ${AWS_PROFILE}
    fi
}

push_to_ecr() {
    # Convert repository name to lowercase
    local ecr_repo_lower=$(echo "${SERVICE_NAME}/${IMAGE_NAME}" | tr '[:upper:]' '[:lower:]')
    ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/${ecr_repo_lower}"
    
    print_green "🏷️ Tagging the Docker image..."
    docker tag ${IMAGE_NAME}:latest "${ECR_URI}:latest"

    print_green "📤 Pushing the Docker image to AWS ECR..."
    if docker push "${ECR_URI}:latest"; then
        print_green "🎉 Successfully pushed image to AWS ECR: ${ECR_URI}"
        
        # Call cleanup function after successful push
        cleanup_old_ecr_images
    else
        print_red "❌ Failed to push the image. Check your Docker and AWS settings."
        exit 1
    fi
}

cleanup_old_ecr_images() {
    print_green "🧹 Cleaning up old ECR images, keeping only the latest 2..."
    
    export ECR_REPO="${SERVICE_NAME}/${IMAGE_NAME}"
    KEEP_COUNT=2
    
    # Get all image digests sorted by date pushed (oldest first)
    IMAGE_DIGESTS=$(aws ecr describe-images \
        --repository-name "${ECR_REPO}" \
        --region $AWS_REGION \
        --profile ${AWS_PROFILE} \
        --query "sort_by(imageDetails,& imagePushedAt)[*].imageDigest" \
        --output text)
    
    # Count how many images we have
    IMAGE_COUNT=$(echo "$IMAGE_DIGESTS" | wc -w)
    
    # If we have more than KEEP_COUNT images, delete the oldest ones
    if [ "$IMAGE_COUNT" -gt "$KEEP_COUNT" ]; then
        # Calculate how many to remove
        TO_DELETE_COUNT=$((IMAGE_COUNT - KEEP_COUNT))
        
        print_green "🗑️ Removing $TO_DELETE_COUNT old ECR images..."
        
        # Get the digests to delete (the oldest ones)
        TO_DELETE=$(echo "$IMAGE_DIGESTS" | tr '\t' '\n' | head -n "$TO_DELETE_COUNT")
        
        for digest in $TO_DELETE; do
            print_green "Deleting image with digest: $digest"
            aws ecr batch-delete-image \
                --repository-name "${ECR_REPO}" \
                --region $AWS_REGION \
                --profile ${AWS_PROFILE} \
                --image-ids imageDigest="$digest"
        done
        
        print_green "✅ Successfully removed old ECR images."
    else
        print_green "ℹ️ No cleanup needed. There are $IMAGE_COUNT images in the repository (keeping $KEEP_COUNT)."
    fi
}

###########################################
# Terraform Utilities
###########################################
init_deployment_vars() {
    local profile=$1
    local environment=$2
    local region=$3

    # Get project name from directory name
    PROJECT_NAME=$(basename $(pwd))

    print_green "Deploying project: ${PROJECT_NAME}"
    print_green "Environment: ${environment}"
    print_green "AWS Profile: ${profile}"
    print_green "AWS Region: ${region}"

    # Create temporary directory for Terraform files
    TEMP_TF_PATH="$(pwd)/infra/terraform/.terraform"
    LOCAL_TF_PLAN="${TEMP_TF_PATH}/${PROJECT_NAME}_${environment}.tfplan"
    mkdir -p $TEMP_TF_PATH
}

###########################################
# Build Container Utilities
###########################################
setup_dockerignore() {
    local DOCKERIGNORE_PATH=".dockerignore"
    if [[ ! -f "$DOCKERIGNORE_PATH" ]]; then
        print_green "📄 Creating .dockerignore file..."
        cat <<EOL > "$DOCKERIGNORE_PATH"
.git
venv
__pycache__
node_modules
EOL
    fi
}



check_dependencies() {
    if [[ " $@ " =~ " --clear " ]]; then
        print_green "✅ Running setup_dependency.sh to initialize the virtual environment..."
        source ./setup_dependency.sh
    else
        print_green "💡 You can run this script with '--clear' to initialize the virtual environment."
        print_green "🔹 Use '--clear' only if you need to set up dependencies for the first time."
    fi
}

set_environment_twilio_livekit_variables() {
    echo "Setting environment variables... on ${TENANT_UPPER} ${STAGE_UPPER}"
    # Set environment variables dynamically
    env_variable_dependencies=("TWILIO_ACCOUNT_SID" "TWILIO_API_KEY" "TWILIO_API_SECRET" "TWILIO_PHONE_ID" "LIVEKIT_API_KEY" "LIVEKIT_API_SECRET" "LIVEKIT_SIP_URL" "LIVEKIT_URL")

    for env_variable in "${env_variable_dependencies[@]}"; do
        var_name="${TENANT_UPPER}_${STAGE_UPPER}_${env_variable}"

        if [ -n "${!var_name}" ]; then
            export "$env_variable=${!var_name}"
        else
            echo "Warning: Environment variable $var_name is not set."
            exit 1
        fi
    done

    export TWILIO_TRUNK_DOMAIN="${project_name}-trunk.pstn.twilio.com"
    export TWILIO_TRUNK_FRIENDLY_NAME="${project_name} LiveKit Trunk"
}