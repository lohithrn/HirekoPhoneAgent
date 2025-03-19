#!/bin/bash

set -e  # Exit on any error
set -x
# Function to set up Twilio trunk
setup_twilio() {
  # Check if required environment variables are set
  if [[ -z "$TWILIO_ACCOUNT_SID" || -z "$TWILIO_API_KEY" || -z "$TWILIO_API_SECRET" || -z "$TWILIO_PHONE_ID" || -z "$TWILIO_TRUNK_DOMAIN" || -z "$TWILIO_TRUNK_FRIENDLY_NAME" || -z "$LIVEKIT_SIP_URL" ]]; then
    echo "One or more required environment variables are not set."
    exit 1
  fi

  # Create Twilio trunk
  echo "Checking if Twilio trunk already exists..."
 TRUNK_SID=$(twilio api trunking v1 trunks list -o json | jq -r ".[] | select(.friendlyName==\"$TWILIO_TRUNK_FRIENDLY_NAME\").sid")
 
  if [ -z "$TRUNK_SID" ]; then
    echo "Creating Twilio trunk..."
    twilio api trunking v1 trunks create \
      --friendly-name "$TWILIO_TRUNK_FRIENDLY_NAME" \
      --domain-name "$TWILIO_TRUNK_DOMAIN"

    # Get the trunk SID
    TRUNK_SID=$(twilio api trunking v1 trunks list -o json | jq -r ".[] | select(.friendlyName==\"$TWILIO_TRUNK_FRIENDLY_NAME\").sid")
  else
    echo "Twilio trunk already exists. Using existing trunk SID: $TRUNK_SID"
  fi

  # Create origination URL
  echo "Creating origination URL..."
  twilio api trunking v1 trunks origination-urls create \
    --trunk-sid $TRUNK_SID \
    --friendly-name "LiveKit SIP URI" \
    --sip-url "$LIVEKIT_SIP_URL" \
    --weight 1 \
    --priority 1 \
    --enabled

  # Map phone number to trunk
  echo "Mapping phone number to trunk..."
  twilio api trunking v1 trunks phone-numbers create \
    --trunk-sid $TRUNK_SID \
    --phone-number-sid "$TWILIO_PHONE_ID"

  export TRUNK_SID
  echo "Twilio setup completed successfully."
  echo "Trunk SID: $TRUNK_SID"
}

