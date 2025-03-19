import os
import setup_twilio
import setup_livekit
import asyncio

async def setup_twilio_livekit_linking(tenant_name, stage, project_name):

    required_env_vars = [
        "TWILIO_ACCOUNT_SID",
        "TWILIO_API_KEY",
        "TWILIO_API_SECRET",
        "TWILIO_PHONE_ID",
        "TWILIO_NUMBER",
        "LIVEKIT_API_KEY",
        "LIVEKIT_API_SECRET",
        "LIVEKIT_SIP_URL",
        "LIVEKIT_URL"
    ]

    prefix = f"{tenant_name.upper()}_{stage.upper()}"

    for var in required_env_vars:
        env_var_name = f"{prefix}_{var}"
        if env_var_name not in os.environ:
            raise EnvironmentError(f"Required environment variable {env_var_name} is not set.")
        os.environ[var] = os.environ[env_var_name]


    twilio_trunk_domain = f"{project_name}-trunk.pstn.twilio.com"
    twilio_trunk_friendly_name = f"{project_name} LiveKit Trunk"
    twilio_account_sid = os.environ["TWILIO_ACCOUNT_SID"]
    twilio_api_key = os.environ["TWILIO_API_KEY"]
    twilio_api_secret = os.environ["TWILIO_API_SECRET"]
    twilio_phone_id = os.environ["TWILIO_PHONE_ID"]
    livekit_sip_url = os.environ["LIVEKIT_SIP_URL"]
    livekit_api_key = os.environ["LIVEKIT_API_KEY"]
    livekit_api_secret = os.environ["LIVEKIT_API_SECRET"]
    livekit_url = os.environ["LIVEKIT_URL"]
    twilio_number = os.environ["TWILIO_NUMBER"]

    return_twilio_data = setup_twilio.setup_twilio(
        twilio_account_sid, 
        twilio_api_key, 
        twilio_api_secret, 
        twilio_phone_id,
        twilio_trunk_domain, 
        twilio_trunk_friendly_name,
        livekit_sip_url, 
        tenant_name, 
        stage
    )


    await setup_livekit.setup_livekit(
        return_twilio_data,
        livekit_api_key,
        livekit_api_secret,
        livekit_sip_url,
        livekit_url,
        twilio_number,
        project_name,
        tenant_name,
        stage
    )

# Define an async main function
async def main():
    await setup_twilio_livekit_linking("hireko", "phone_local", "HirekoPhoneAgent")

# Run the async main function
if __name__ == "__main__":
    asyncio.run(main())
