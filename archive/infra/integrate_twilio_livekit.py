import subprocess

def cleanup(trunk_sid, trunk_id, dispatch_id):
    if not trunk_sid or not trunk_id or not dispatch_id:
        return

    print("Cleaning up resources...")

    # Delete LiveKit trunk
    if subprocess.call(['lk', 'sip', 'inbound', 'delete', trunk_id]) != 0:
        print("Failed to delete LiveKit trunk")
        return

    # Delete dispatch rule
    if subprocess.call(['lk', 'sip', 'dispatch', 'delete', dispatch_id]) != 0:
        print("Failed to delete dispatch rule")
        return

    # Delete Twilio trunk
    if subprocess.call(['twilio', 'api', 'trunking', 'v1', 'trunks', 'remove', '--sid', trunk_sid]) != 0:
        print("Failed to delete Twilio trunk")
        return

    print("Cleanup completed successfully.")

def setup(setup_twilio_func, setup_livekit_func):
    setup_twilio_func()
    setup_livekit_func()

def clean_fresh_setup(trunk_sid, trunk_id, dispatch_id, setup_twilio_func, setup_livekit_func):
    cleanup(trunk_sid, trunk_id, dispatch_id)
    setup(setup_twilio_func, setup_livekit_func) 