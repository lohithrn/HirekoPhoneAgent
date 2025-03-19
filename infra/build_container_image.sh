#!/bin/bash
set -x

# Print utilities
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

load_environment_variables() {
    local env_prefix="${TENANT_UPPER}_${STAGE_UPPER}"
    
    local env_variable_dependencies=( "TWILIO_ACCOUNT_SID" "TWILIO_API_KEY" "TWILIO_API_SECRET" "TWILIO_PHONE_ID" "TWILIO_PHONE_NUMBER" "LIVEKIT_SIP_URL" "LIVEKIT_URL"  "LIVEKIT_API_KEY" "LIVEKIT_API_SECRET" "GROQ_API_KEY" "DEEPGRAM_API_KEY"  "CARTESIA_API_KEY")

    for env_variable in "${env_variable_dependencies[@]}"; do
        local var_name="${env_prefix}_${var}"
        export $var=${!var_name:?Environment variable $var_name is required}
    done

    export AWS_ACCESS_KEY_ID=$(aws configure get ${tenant_name}.aws_access_key_id)
    export AWS_SECRET_ACCESS_KEY=$(aws configure get ${tenant_name}.aws_secret_access_key)
    export AWS_REGION=$(aws configure get ${tenant_name}.aws_region || echo "us-west-2")

    export SSH_PASSWORD="developer"
}

setup_docker_config() {
    # Convert to lowercase for Docker naming conventions
    local service_name_lower=$(echo ${SERVICE_NAME} | tr '[:upper:]' '[:lower:]')
    local tenant_lower=$(echo ${tenant_name} | tr '[:upper:]' '[:lower:]')
    local stage_lower=$(echo ${stage} | tr '[:upper:]' '[:lower:]')
    
    # Build container and image names
    CONTAINER_NAME="${service_name_lower}_${tenant_lower}_${stage_lower}_container"
    IMAGE_NAME="${service_name_lower}_${tenant_lower}_${stage_lower}_image"
    
    export DOCKER_CLI_EXPERIMENTAL=enabled
}

build_docker_image() {
    print_green "🚀 Building Docker image..."
    docker build \
        --platform linux/arm64 \
        --build-arg LIVEKIT_URL="${LIVEKIT_URL}" \
        --build-arg LIVEKIT_API_KEY="${LIVEKIT_API_KEY}" \
        --build-arg LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET}" \
        --build-arg GROQ_API_KEY="${GROQ_API_KEY}" \
        --build-arg DEEPGRAM_API_KEY="${DEEPGRAM_API_KEY}" \
        --build-arg CARTESIA_API_KEY="${CARTESIA_API_KEY}" \
        --build-arg SSH_PASSWORD="${SSH_PASSWORD}" \
        --build-arg AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
        --build-arg AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
        --build-arg AWS_REGION="${AWS_REGION}" \
        --build-arg tenant_name="${tenant_name}" \
        --build-arg venv_name="${VENV_NAME}" \
        -t ${IMAGE_NAME} .
}

build_container_image() {
    setup_dockerignore
    check_dependencies "$@"
    load_environment_variables
    setup_docker_config
    build_docker_image
}
