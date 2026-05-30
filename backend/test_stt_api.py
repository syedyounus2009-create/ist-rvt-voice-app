"""
IST-RVT Speech-to-Text API Verification Script
Tests that backend imports are valid and measures transcription latency.
"""
import asyncio
import os
import sys
import time

# Ensure we can import from backend
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

async def main():
    print("=== IST-RVT STT Engine Test ===")
    from config import settings
    from services.stt_service import stt_service

    print(f"Current STT Provider: {settings.STT_PROVIDER}")
    print(f"Groq API Key configured: {'Yes' if settings.GROQ_API_KEY and 'your' not in settings.GROQ_API_KEY else 'No'}")
    print(f"OpenAI API Key configured: {'Yes' if settings.OPENAI_API_KEY and 'your' not in settings.OPENAI_API_KEY else 'No'}")

    # Generate a dummy 1-second PCM16 mono 16kHz silent audio clip (32000 bytes)
    # 1 second * 16000 samples/sec * 2 bytes/sample = 32000 bytes
    dummy_pcm = b"\x00" * 32000

    print("\nInitializing STT Service...")
    start_init = time.perf_counter()
    await stt_service.initialize()
    init_latency = (time.perf_counter() - start_init) * 1000
    print(f"STT Initialized in {init_latency:.1f}ms")

    print("\nRunning dummy transcription test (silent audio)...")
    try:
        result = await stt_service.transcribe(dummy_pcm, language="en")
        print("\nSuccess! Result:")
        print(f"  Detected Language: {result['language']}")
        print(f"  Transcription Text: '{result['text']}'")
        print(f"  Transcription Latency: {result['latency_ms']}ms")
    except Exception as e:
        print(f"\n❌ Transcription error: {e}")
        print("This is expected if API keys are placeholders or invalid.")

if __name__ == "__main__":
    asyncio.run(main())
