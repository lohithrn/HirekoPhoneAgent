import subprocess
import json
from twilio.rest import Client


def setup_twilio(twilio_account_sid, twilio_api_key, twilio_api_secret, twilio_phone_id, twilio_trunk_domain, twilio_trunk_friendly_name, livekit_sip_url, tenant_name, stage):
    
    if not all([twilio_account_sid, twilio_api_key, twilio_api_secret, twilio_phone_id, twilio_trunk_domain, twilio_trunk_friendly_name, livekit_sip_url, tenant_name, stage]):
        print("One or more required parameters are not set.")
        return None

    client = Client(twilio_api_key, twilio_api_secret, twilio_account_sid)
    trunks = client.trunking.trunks.list()
    trunks = [trunk for trunk in trunks if trunk.friendly_name == twilio_trunk_friendly_name]
    
    trunking_exists = len(trunks) > 0

    trunk = trunks[0] if trunking_exists else None

    if not trunking_exists:
        print("Twilio trunk already exists.")
        trunk = client.trunking.trunks.create(
            friendly_name=twilio_trunk_friendly_name,
            domain_name=twilio_trunk_domain
        )

    list_origination_urls = trunk.origination_urls.list()
    
    list_origination_urls = [origination_url for origination_url in list_origination_urls if origination_url.sip_url == livekit_sip_url]

    if len(list_origination_urls) == 0:
        origination_url = trunk.origination_urls.create(
            friendly_name=twilio_trunk_friendly_name,
            sip_url=livekit_sip_url,
            weight=1,
            priority=1,
            enabled=True
        )
        print(f"Origination URL created: {origination_url.sid}")

    list_phone_numbers = trunk.phone_numbers.list()

    list_phone_numbers = [phone_number for phone_number in list_phone_numbers if phone_number.phone_number == twilio_phone_id]

    phone_number = list_phone_numbers[0] if len(list_phone_numbers) > 0 else None
    if len(list_phone_numbers) == 0:
        phone_number = trunk.phone_numbers.create(
            phone_number_sid=twilio_phone_id
        )
        print(f"Phone number created: {phone_number.sid}")


    list_credential_lists = client.sip.credential_lists.list()
    list_credential_lists = [credential_list for credential_list in list_credential_lists if credential_list.friendly_name == twilio_trunk_friendly_name]
    for cred in list_credential_lists:
        cred.delete()

    credential_list = client.sip.credential_lists.create(friendly_name=twilio_trunk_friendly_name)
    token_name = f"{tenant_name.upper()}2{stage.lower()}"
    credential = client.sip.credential_lists(credential_list.sid).credentials.create(username=tenant_name, password=token_name)

     
    return {
        "trunk_sid": trunk.sid,
        "trunk_domain": f"{trunk.domain_name}.pstn.twilio.com",
        "trunk_url": trunk.url,
        "credential_list_sid": credential_list.sid,
        "credential_sid": credential.sid,
        "phone_number_sid": phone_number.sid,
        "phone_number": phone_number.phone_number
    }

 