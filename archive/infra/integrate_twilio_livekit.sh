#!/bin/bash

set -e  # Exit on any error

set -x 



# Function to clean up resources
cleanup() {
  # Load variables from setup scripts
  source "$(dirname "$(realpath "$0")")/infra/setup_twilio.sh"
  source "$(dirname "$(realpath "$0")")/infra/setup_livekit.sh"
  
  if [[ -z "$TRUNK_SID" || -z "$TRUNK_ID" || -z "$DISPATCH_ID" ]]; then
    return
  fi

  TRUNK_SID=$TRUNK_SID
  TRUNK_ID=$TRUNK_ID
  DISPATCH_ID=$DISPATCH_ID

  echo "Cleaning up resources..."

  # Delete LiveKit trunk
  if ! lk sip inbound delete $TRUNK_ID; then
    echo "Failed to delete LiveKit trunk"
    exit 1
  fi

  # Delete dispatch rule
  if ! lk sip dispatch delete $DISPATCH_ID; then
    echo "Failed to delete dispatch rule"
    exit 1
  fi

  # Delete Twilio trunk
  if ! twilio api trunking v1 trunks remove --sid $TRUNK_SID; then
    echo "Failed to delete Twilio trunk"
    exit 1
  fi

  echo "Cleanup completed successfully."
}

# Function to set up resources
setup() {
  # Call setup scripts
  setup_twilio
  setup_livekit
}


clean_fresh_setup() {
  # Call cleanup before setup
  cleanup
  setup
}



# Uncomment the following line to enable cleanup on script exit
# trap cleanup EXIT 