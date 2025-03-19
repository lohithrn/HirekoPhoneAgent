import os
import asyncio
from livekit.plugins.openai import llm
from livekit.agents import JobContext, WorkerOptions, cli, JobProcess
from livekit.agents.llm import (
    ChatContext,
    ChatMessage,
)
from livekit.agents.voice_assistant import VoiceAssistant
from livekit.plugins import deepgram, silero, cartesia, openai, aws

from dotenv import load_dotenv

from agent.prompts import get_interview_chat_context

load_dotenv()

def prewarm(proc: JobProcess):
    vad_model = silero.VAD.load(
        min_speech_duration=0.2,
        min_silence_duration=2.0,
        prefix_padding_duration=0.5,
        activation_threshold=0.5,
        sample_rate=16000,
        force_cpu=True
    )
    proc.userdata["vad"] = vad_model


async def entrypoint(ctx: JobContext):
    initial_ctx = get_interview_chat_context(ctx.room.name)

    groq_llm = llm.LLM.with_groq(model="gemma2-9b-it", temperature=0.5)

    vad_model = silero.VAD.load(
        min_speech_duration=0.2,
        min_silence_duration=2.0,
        prefix_padding_duration=0.5,
        activation_threshold=0.5,
        sample_rate=16000,
        force_cpu=True
    )

    
    tts = aws.TTS(voice="Ruth")
    stt = aws.STT()
    #tts_cartesia = cartesia.TTS(voice="248be419-c632-4f23-adf1-5324ed7dbf1d")
    #tts_cartesia = cartesia.TTS(voice="a38e4e85-e815-43ab-acf1-907c4688dd6c")
    assistant = VoiceAssistant(
        vad=ctx.proc.userdata["vad"],
        stt=stt,
        llm=groq_llm,
        tts=tts,
        chat_ctx=initial_ctx,
    )

    await ctx.connect()
    assistant.start(ctx.room)
    await asyncio.sleep(1)
    await assistant.say("Hi I'm Katie ! welcome to the interview, whats your name?", allow_interruptions=True)


if __name__ == "__main__":


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
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint, prewarm_fnc=prewarm))
