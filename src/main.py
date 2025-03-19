from livekit.agents import WorkerOptions, cli, JobRequest
from agent.agent_start import entrypoint as entrypoint_one, prewarm
import os
from dotenv import load_dotenv

# Load environment variables from .env.local
load_dotenv('.env.local')

def run_worker_one():


    required_env_vars = [
        "LIVEKIT_URL",
        "LIVEKIT_API_KEY",
        "LIVEKIT_API_SECRET",
        "GROQ_API_KEY",
        "DEEPGRAM_API_KEY",
        "CARTESIA_API_KEY"
    ]

    for var in required_env_vars:
        if not os.getenv(var):
            raise EnvironmentError(f"Required environment variable {var} is not set.")
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint_one, prewarm_fnc=prewarm))



if __name__ == "__main__":  
    run_worker_one()
    
    
