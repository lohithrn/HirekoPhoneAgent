#!/bin/bash
set -x

export tenant_name="hireko"

# Source utility functions
source ./infra/utils.sh
source ./infra/build_container_image.sh

manage_container() {
    if docker ps -q --filter "name=${CONTAINER_NAME}" | grep -q .; then
        print_red "🛑 Stopping running container: ${CONTAINER_NAME}..."
        docker stop ${CONTAINER_NAME} && docker rm ${CONTAINER_NAME}
    fi
}

run_container() {
    print_green "🐳 Starting Docker container..."
    nohup docker run --name ${CONTAINER_NAME} \
        -p 2950-2999:2950-2999 \
        -p 2222:22 \
        -p 80:80 \
        -p 443:443 \
        -p 0.0.0.0:5222:5222 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -dit ${IMAGE_NAME} > docker_output.log 2>&1 &
}

main() {
    setup_environment_local
    check_docker_daemon
    build_container_image "$@"
    manage_container
    run_container
    
    # Wait for container to fully start
    sleep 2
    
    # Show files in the container
    print_green "📂 Listing files in the container:"
    docker exec ${CONTAINER_NAME} ls -la /app
    #docker exec -it --user root <container_id_or_name> /bin/bash
}


setup_environment_local() {
    export tenant_name="hireko"
    export VENV_NAME="${tenant_name}_venv"
    export stage="LOCAL"
    export SERVICE_NAME=$(basename "$PWD")

    export PROFILE=${tenant_name}
    export ENVIRONMENT=${stage}    
    export REGION=${4:-"us-west-2"} 
    export PROJECT_NAME=${SERVICE_NAME}
    
    export TENANT_UPPER=$(echo ${tenant_name} | tr '[:lower:]' '[:upper:]')
    export STAGE_UPPER=$(echo ${stage} | tr '[:lower:]' '[:upper:]')

    # Copy the beta environment file to env_export.sh for local
    cp z_beta_url_env env_export.sh
}

# Execute main function
main "$@"

