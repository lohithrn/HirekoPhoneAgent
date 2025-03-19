import subprocess
import json

def setup_twilio(twilio_account_sid, twilio_api_key, twilio_api_secret, twilio_phone_id, twilio_trunk_domain, twilio_trunk_friendly_name, livekit_sip_url):
    if not all([twilio_account_sid, twilio_api_key, twilio_api_secret, twilio_phone_id, twilio_trunk_domain, twilio_trunk_friendly_name, livekit_sip_url]):
        print("One or more required parameters are not set.")
        return None

    print("Checking if Twilio trunk already exists...")
    result = subprocess.run(['twilio', 'api', 'trunking', 'v1', 'trunks', 'list', '-o', 'json'], capture_output=True, text=True)
    trunk_sid = None
    if result.returncode == 0:
        trunks = json.loads(result.stdout)
        for trunk in trunks:
            if trunk.get('friendlyName') == twilio_trunk_friendly_name:
                trunk_sid = trunk.get('sid')
                break

    if not trunk_sid:
        print("Creating Twilio trunk...")
        subprocess.run([
            'twilio', 'api', 'trunking', 'v1', 'trunks', 'create',
            '--friendly-name', twilio_trunk_friendly_name,
            '--domain-name', twilio_trunk_domain
        ])
        result = subprocess.run(['twilio', 'api', 'trunking', 'v1', 'trunks', 'list', '-o', 'json'], capture_output=True, text=True)
        if result.returncode == 0:
            trunks = json.loads(result.stdout)
            for trunk in trunks:
                if trunk.get('friendlyName') == twilio_trunk_friendly_name:
                    trunk_sid = trunk.get('sid')
                    break
    else:
        print(f"Twilio trunk already exists. Using existing trunk SID: {trunk_sid}")

    if trunk_sid:
        print("Creating origination URL...")
        subprocess.run([
            'twilio', 'api', 'trunking', 'v1', 'trunks', 'origination-urls', 'create',
            '--trunk-sid', trunk_sid,
            '--friendly-name', "LiveKit SIP URI",
            '--sip-url', livekit_sip_url,
            '--weight', '1',
            '--priority', '1',
            '--enabled'
        ])

        print("Mapping phone number to trunk...")
        subprocess.run([
            'twilio', 'api', 'trunking', 'v1', 'trunks', 'phone-numbers', 'create',
            '--trunk-sid', trunk_sid,
            '--phone-number-sid', twilio_phone_id
        ])

    print("Twilio setup completed successfully.")
    print(f"Trunk SID: {trunk_sid}")
    return trunk_sid 