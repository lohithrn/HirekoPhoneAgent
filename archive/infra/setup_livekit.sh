#!/bin/bash

set -e  # Exit on any error
set -x

create_directory_if_not_exists() {
  local dir_path=$1
  if [ ! -d "$dir_path" ]; then
    echo "Directory does not exist. Creating directory..."
    mkdir -p "$dir_path"
  fi
}

create_dispatch_rule() {
  echo "Creating dispatch rule..."
  result=$(check_trunk_id)
  TRUNK_ID=$(echo $result | cut -d' ' -f1)
  found_phone_registered=$(echo $result | cut -d' ' -f2)

  directroy_to_sip_dispatch_id="artifacts/${tenant_name}/${stage}/dispatches/"

  dispatch_config_path=${directroy_to_sip_dispatch_id}${TRUNK_ID}.json

  if [ -f "$dispatch_config_path" ]; then
    echo "File $dispatch_config_path already exists. Deleting the existing file..."
    rm -f "$dispatch_config_path"
  fi

  create_directory_if_not_exists "$(dirname "$dispatch_config_path")"
  cat <<EOF > "$dispatch_config_path"
{
  "name": "Default dispatch rule",
  "trunk_ids": ["$TRUNK_ID"],
  "rule": {
        "dispatchRuleIndividual": {}
    }
}
EOF

  if ! export DISPATCH_ID=$(lk sip dispatch create "$dispatch_config_path"); then
    echo "Error: Failed to create dispatch rule."
    exit 1
  fi
  echo "Dispatch rule created: $DISPATCH_ID"
  lk sip dispatch list
}

 check_trunk_id() {
    local found_phone_registered=false
    local trunk_id="-"

    for file in artifacts/${tenant_name}/${stage}/trunk_id/*; do
      [ -e "$file" ] || continue
      TWILIO_PHONE_ID_TEMP=$(cat "$file")
      if [ "$TWILIO_PHONE_ID" == "$TWILIO_PHONE_ID_TEMP" ]; then
        found_phone_registered=true
        trunk_id=$(basename "$file")
        break
      fi
    done

    echo "$trunk_id $found_phone_registered"
    return 0
}

create_livekit_trunk() {
  echo "Creating LiveKit trunk... and this is important command"
  lk sip inbound delete ST_tDrZbaRjQeJy
  lk sip inbound list 
  #lk sip inbound delete  ST_bNt892L9vYHH  is the command to delete the trunk

  found_phone_registered=false
  directroy_to_sip_trunk_id="artifacts/${tenant_name}/${stage}/trunk_id/"
  create_directory_if_not_exists $directroy_to_sip_trunk_id
  
  result=$(check_trunk_id)
  TRUNK_ID=$(echo $result | cut -d' ' -f1)
  found_phone_registered=$(echo $result | cut -d' ' -f2)

  
  trunk_config_path="artifacts/${tenant_name}/${stage}/inbound-trunk.json"
  if [ "$found_phone_registered" = false ]; then
    cat <<EOF > $trunk_config_path
{
  "trunk": {
    "name": "Twilio inbound trunk",
    "numbers": ["9257447356", "+19257447356"]
  }
}
EOF
    # Execute the command using the JSON file
    export TRUNK_ID=$(lk sip inbound create $trunk_config_path)
    TRUNK_ID=$(echo $TRUNK_ID | grep -o 'SIPTrunkID: .*' | cut -d' ' -f2)

    echo "TRUNK_ID: $TRUNK_ID"
    touch artifacts/${tenant_name}/${stage}/trunk_id/$TRUNK_ID
    echo $TWILIO_PHONE_ID > artifacts/${tenant_name}/${stage}/trunk_id/$TRUNK_ID
  fi

  lk sip inbound list
  echo "Done."
}

# Function to set up LiveKit trunk and dispatch rule
setup_livekit() {
  # Check if required environment variables are set
  if [[ -z "$LIVEKIT_API_KEY" || -z "$LIVEKIT_API_SECRET" || -z "$LIVEKIT_SIP_URL" || -z "$LIVEKIT_URL" || -z "$TWILIO_PHONE_ID" ]]; then
    echo "One or more required environment variables are not set."
    exit 1
  fi

  # Create LiveKit trunk
  echo "About to create LiveKit trunk..."

  create_livekit_trunk

  if [ -z "$TRUNK_ID" ]; then
    echo "Failed to capture trunk ID" >&2
    exit 1
  fi

  create_dispatch_rule

}

