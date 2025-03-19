#!/bin/bash
set -x

setup_environment_prod() {
    export tenant_name="hireko"
    export VENV_NAME="${tenant_name}_venv"
    export stage="PROD"
    export SERVICE_NAME=$(basename "$PWD")

    PROFILE=${tenant_name}
    ENVIRONMENT=${stage}    
    REGION=${4:-"us-west-2"} 
    PROJECT_NAME=${SERVICE_NAME}
    
    export TENANT_UPPER=$(echo ${tenant_name} | tr '[:lower:]' '[:upper:]')
    export STAGE_UPPER=$(echo ${stage} | tr '[:lower:]' '[:upper:]')

    # Copy the prod environment file to env_export.sh
    cp z_prod_url_env env_export.sh
}

# AWS Configuration
AWS_REGION="us-west-2"
AWS_PROFILE="hireko"

# Source utility functions
source ./infra/utils.sh
source ./infra/build_container_image.sh
source ./infra/terraform_utils.sh

main() {
    setup_environment_prod
    check_docker_daemon
    build_container_image "$@"
    setup_aws
    setup_ecr
    push_to_ecr
    deploy_terraform "$PROFILE" "$ENVIRONMENT" "$REGION" "$PROJECT_NAME"
}

# Execute main function
main "$@"
