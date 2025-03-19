#! /bin/bash
set -e
set -x

export tenant_name="hireko"
export project_name=$(basename "$PWD")
export stage="phone"
export STAGE_UPPER=$(echo "$stage" | tr '[:lower:]' '[:upper:]')
export TENANT_UPPER=$(echo "$tenant_name" | tr '[:lower:]' '[:upper:]')
# Set environment variables

source ./infra/utils.sh
source ./infra/setup_twilio.sh
source ./infra/setup_livekit.sh
source ./infra/integrate_twilio_livekit.sh
# Call the function to set environment variables
set_environment_twilio_livekit_variables
# Call the function to set environment variables
set_environment_twilio_livekit_variables
clean_fresh_setup