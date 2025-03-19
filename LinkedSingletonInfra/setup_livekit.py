import os
import subprocess
import json
import asyncio
from livekit import api
from livekit.api import SIPInboundTrunkInfo


async def setup_livekit(return_twilio_data, livekit_api_key, livekit_api_secret, livekit_sip_url, livekit_url, twilio_number, project_name, tenant_name, stage, delete_existing_trunks=False):

    if not all([return_twilio_data, livekit_api_key, livekit_api_secret, livekit_sip_url, livekit_url, twilio_number, project_name, tenant_name, stage]):
        raise ValueError("One or more required parameters are missing or invalid.")
    
    livekit_api = api.LiveKitAPI()
    try:
        rules = await livekit_api.sip.list_sip_inbound_trunk(
            api.ListSIPInboundTrunkRequest()
        )

        print(f"{rules}")

        if delete_existing_trunks:
            for rule in rules.items:
                request = api.DeleteSIPTrunkRequest(
                    sip_trunk_id=rules.items[0].sip_trunk_id
                )
                await livekit_api.sip.delete_sip_trunk(request)
            rules = await livekit_api.sip.list_sip_inbound_trunk(api.ListSIPInboundTrunkRequest())

        trunk_id = None
        for rule in rules.items:
            if rule.name == f"{project_name} inbound trunk":
                print(f"{rule}")
                trunk_id = rule.sip_trunk_id
        
        if trunk_id is None:
            sip_trunk_info = SIPInboundTrunkInfo(
                    name=f"{project_name} inbound trunk",
                    numbers=[return_twilio_data["phone_number"]] 
                )
            request = api.CreateSIPInboundTrunkRequest(
                trunk=sip_trunk_info
            )
            trunk = await livekit_api.sip.create_sip_inbound_trunk(request)
            trunk_id = trunk.sip_trunk_id

        existing_dispatch_rules = await livekit_api.sip.list_sip_dispatch_rule(api.ListSIPDispatchRuleRequest())
        
        print(f"Existing dispatch rules: {existing_dispatch_rules}")
        
        trunk_id_exists = False
        for rule in existing_dispatch_rules.items:
            for trunk in rule.trunk_ids:
                if trunk_id in trunk:
                    trunk_id_exists = True
                    break
            if trunk_id_exists:
                break
        
        print(f"{trunk_id_exists}")

        if not trunk_id_exists:
            request = api.CreateSIPDispatchRuleRequest(
            name=f"{project_name} dispatch rule",
            trunk_ids=[f"{trunk_id}"],
            rule=api.SIPDispatchRule(
                    dispatch_rule_individual=api.SIPDispatchRuleIndividual()  # Empty object
                )
            )
            dispatch = await livekit_api.sip.create_sip_dispatch_rule(request)
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        await livekit_api.aclose()

