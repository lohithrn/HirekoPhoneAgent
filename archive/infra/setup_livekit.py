import os
import subprocess
import json

def create_directory_if_not_exists(dir_path):
    if not os.path.exists(dir_path):
        print("Directory does not exist. Creating directory...")
        os.makedirs(dir_path)

def create_dispatch_rule(trunk_id, tenant_name, stage):
    print("Creating dispatch rule...")
    directory_to_sip_dispatch_id = f"artifacts/{tenant_name}/{stage}/dispatches/"
    dispatch_config_path = f"{directory_to_sip_dispatch_id}{trunk_id}.json"

    if os.path.exists(dispatch_config_path):
        print(f"File {dispatch_config_path} already exists. Deleting the existing file...")
        os.remove(dispatch_config_path)

    create_directory_if_not_exists(os.path.dirname(dispatch_config_path))
    dispatch_rule = {
        "name": "Default dispatch rule",
        "trunk_ids": [trunk_id],
        "rule": {"type": "default"}
    }

    with open(dispatch_config_path, 'w') as f:
        json.dump(dispatch_rule, f)

    result = subprocess.run(['lk', 'sip', 'dispatch', 'create', dispatch_config_path], capture_output=True, text=True)
    if result.returncode != 0:
        print("Error: Failed to create dispatch rule.")
        return None

    dispatch_id = result.stdout.strip()
    print(f"Dispatch rule created: {dispatch_id}")
    subprocess.run(['lk', 'sip', 'dispatch', 'list'])
    return dispatch_id

def create_livekit_trunk(twilio_phone_id, tenant_name, stage):
    print("Creating LiveKit trunk...")
    directory_to_sip_trunk_id = f"artifacts/{tenant_name}/{stage}/trunk_id/"
    create_directory_if_not_exists(directory_to_sip_trunk_id)

    trunk_config_path = f"artifacts/{tenant_name}/{stage}/inbound-trunk.json"
    trunk_data = {
        "trunk": {
            "name": "Twilio inbound trunk",
            "numbers": [twilio_phone_id]
        }
    }

    with open(trunk_config_path, 'w') as f:
        json.dump(trunk_data, f)

    result = subprocess.run(['lk', 'sip', 'inbound', 'create', trunk_config_path], capture_output=True, text=True)
    if result.returncode != 0:
        print("Error: Failed to create LiveKit trunk.")
        return None

    trunk_id = result.stdout.strip().split()[-1]
    print(f"TRUNK_ID: {trunk_id}")
    with open(f"{directory_to_sip_trunk_id}{trunk_id}", 'w') as f:
        f.write(twilio_phone_id)
    return trunk_id

def setup_livekit(livekit_api_key, livekit_api_secret, livekit_sip_url, livekit_url, twilio_phone_id, tenant_name, stage):
    if not all([livekit_api_key, livekit_api_secret, livekit_sip_url, livekit_url, twilio_phone_id]):
        print("One or more required parameters are not set.")
        return None, None

    print("About to create LiveKit trunk...")
    trunk_id = create_livekit_trunk(twilio_phone_id, tenant_name, stage)
    if not trunk_id:
        print("Failed to capture trunk ID")
        return None, None

    dispatch_id = create_dispatch_rule(trunk_id, tenant_name, stage)
    return trunk_id, dispatch_id 