import os
from infra.utils import set_environment_twilio_livekit_variables
from infra.setup_twilio import setup_twilio
from infra.setup_livekit import setup_livekit
from infra.integrate_twilio_livekit import clean_fresh_setup

def main():
    tenant_name = "hireko"
    project_name = os.path.basename(os.getcwd())
    stage = "phone"
    stage_upper = stage.upper()
    tenant_upper = tenant_name.upper()

    # Set environment variables
    twilio_account_sid = os.getenv(f"{tenant_upper}_{stage_upper}_TWILIO_ACCOUNT_SID")
    twilio_api_key = os.getenv(f"{tenant_upper}_{stage_upper}_TWILIO_API_KEY")
    twilio_api_secret = os.getenv(f"{tenant_upper}_{stage_upper}_TWILIO_API_SECRET")
    twilio_phone_id = os.getenv(f"{tenant_upper}_{stage_upper}_TWILIO_PHONE_ID")
    livekit_api_key = os.getenv(f"{tenant_upper}_{stage_upper}_LIVEKIT_API_KEY")
    livekit_api_secret = os.getenv(f"{tenant_upper}_{stage_upper}_LIVEKIT_API_SECRET")
    livekit_sip_url = os.getenv(f"{tenant_upper}_{stage_upper}_LIVEKIT_SIP_URL")
    livekit_url = os.getenv(f"{tenant_upper}_{stage_upper}_LIVEKIT_URL")

    twilio_trunk_domain = f"{project_name}-trunk.pstn.twilio.com"
    twilio_trunk_friendly_name = f"{project_name} LiveKit Trunk"

    trunk_sid = setup_twilio(twilio_account_sid, twilio_api_key, twilio_api_secret, twilio_phone_id, twilio_trunk_domain, twilio_trunk_friendly_name, livekit_sip_url)
    trunk_id, dispatch_id = setup_livekit(livekit_api_key, livekit_api_secret, livekit_sip_url, livekit_url, twilio_phone_id, tenant_name, stage)

    clean_fresh_setup(trunk_sid, trunk_id, dispatch_id, lambda: setup_twilio(twilio_account_sid, twilio_api_key, twilio_api_secret, twilio_phone_id, twilio_trunk_domain, twilio_trunk_friendly_name, livekit_sip_url), lambda: setup_livekit(livekit_api_key, livekit_api_secret, livekit_sip_url, livekit_url, twilio_phone_id, tenant_name, stage))

if __name__ == "__main__":
    main() 