
#!/bin/bash
set -x
set -e


export tenant_name="hireko"

# Source utility functions
source ./infra/utils.sh
source ./infra/build_container_image.sh

setup_environment_local() {
    export tenant_name="hireko"
    export VENV_NAME="${tenant_name}_venv"
    export stage="PROD"
    export SERVICE_NAME=$(basename "$PWD")

    export PROFILE=${tenant_name}
    export ENVIRONMENT=${stage}    
    export REGION=${4:-"us-west-2"} 
    export PROJECT_NAME=${SERVICE_NAME}
    
    export TENANT_UPPER=$(echo ${tenant_name} | tr '[:lower:]' '[:upper:]')
    export STAGE_UPPER=$(echo ${stage} | tr '[:lower:]' '[:upper:]')

}


main() {
    setup_environment_local
    load_environment_variables
    export PYTHONPATH=$PYTHONPATH:$(pwd)/LinkedSingletonInfra
    python3 LinkedSingletonInfra/integrate_twilio_livekit.py
}



main "$@"

