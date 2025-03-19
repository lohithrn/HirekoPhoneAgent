#! /bin/bash
set -e
set -x

install_cli_tools() {
  echo "Installing twilio-cli"
  npm install -g twilio-cli

  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Installing livekit-cli on macOS"
    brew update && brew install livekit-cli
  else
    echo "Skipping livekit-cli installation as the OS is not macOS."
  fi
}

# Call the function to install CLI tools
install_cli_tools

export tenant_name="hireko"
export project_name=$(basename "$PWD")
export stage="phone_local"
export STAGE_UPPER=$(echo "$stage" | tr '[:lower:]' '[:upper:]')
export TENANT_UPPER=$(echo "$tenant_name" | tr '[:lower:]' '[:upper:]')
# Set environment variables

source ./infra/utils.sh
source ./infra/setup_twilio.sh
source ./infra/setup_livekit.sh
source ./infra/integrate_twilio_livekit.sh
# Call the function to set environment variables
set_environment_twilio_livekit_variables
clean_fresh_setup