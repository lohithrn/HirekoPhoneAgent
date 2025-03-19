#!/bin/bash
set -x
set -e

export tenant_name="hireko"

source ./infra/utils.sh

setup_venv_on_local_machine() {
    venv_name=${venv_name:-venv}
    venv_path=$(pwd)/$venv_name
    python3 -m venv $venv_path
    source $venv_path/bin/activate
    $venv_path/bin/pip3 install --upgrade pip
    $venv_path/bin/pip3 install -r requirements.txt
}

main() {
    setup_environment_local
    setup_venv_on_local_machine

    rm -rf nohup.out

    echo "Setting environment variables... on ${TENANT_UPPER} ${STAGE_UPPER}"
    # Set environment variables dynamically

 
    env_variable_dependencies=("LIVEKIT_SIP_URL" "LIVEKIT_URL"  "GROQ_API_KEY" "DEEPGRAM_API_KEY" "LIVEKIT_API_KEY" "LIVEKIT_API_SECRET" "CARTESIA_API_KEY" "TWILIO_ACCOUNT_SID" "TWILIO_API_KEY" "TWILIO_API_SECRET" "TWILIO_PHONE_ID")

    for env_variable in "${env_variable_dependencies[@]}"; do
        var_name="${TENANT_UPPER}_${STAGE_UPPER}_${env_variable}"

        if [ -n "${!var_name}" ]; then
            export "$env_variable=${!var_name}"
        else
            echo "Warning: Environment variable $var_name is not set."
            exit 1
        fi
    done

    # Run main.py and app.py using nohup to prevent blocking, without redirecting output
    export AWS_ACCESS_KEY_ID=$(aws configure get ${tenant_name}.aws_access_key_id)
    export AWS_SECRET_ACCESS_KEY=$(aws configure get ${tenant_name}.aws_secret_access_key)
    export AWS_REGION=$(aws configure get ${tenant_name}.aws_region || echo "us-west-2")

    # Check if environment variables are set and not null
    for env_variable in "${env_variable_dependencies[@]}"; do
        if [ -z "${!env_variable}" ]; then
            echo "Error: Environment variable $env_variable is not set or is null."
            exit 1
        fi
    done

    nohup python3 test/app.py &
    ps aux | grep 'app.py' &
    ps aux | grep '[m]ain.py' &
    python3 src/main.py start
}

# Execute main function
main "$@"
