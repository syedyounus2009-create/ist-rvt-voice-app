"""
IST-RVT Speech-to-Text Service
- Supports dynamic providers: "local" (faster-whisper), "groq" (fast API), "openai" (OpenAI API)
- Automatic fallback: API errors fall back dynamically to local CPU Whisper
- Silero VAD / RMS vocal detection for millisecond speech streaming
- In-memory WAV wrapping for PCM16 audio compatibility with cloud endpoints
"""

import asyncio
import io
import logging
import time
from typing import Optional

from config import settings

logger = logging.getLogger(__name__)


class STTService:
    def __init__(self):
        self.model = None
        self._initialized = False

    async def initialize(self):
        """Lazy-load models on first use based on provider choice."""
        if self._initialized:
            return

        provider = settings.STT_PROVIDER.lower()
        if provider == "groq":
            if not settings.GROQ_API_KEY:
                logger.warning("⚠️ GROQ_API_KEY is not configured. Falling back to local STT.")
            else:
                self._initialized = True
                logger.info("✅ STT ready — Cloud API (Groq: Whisper Large v3)")
                return
        elif provider == "openai":
            if not settings.OPENAI_API_KEY:
                logger.warning("⚠️ OPENAI_API_KEY is not configured. Falling back to local STT.")
            else:
                self._initialized = True
                logger.info("✅ STT ready — Cloud API (OpenAI: Whisper-1)")
                return

        # Local fallback or primary
        logger.info("🔄 Loading local faster-whisper model (this can take up to 2GB RAM)...")
        await asyncio.get_event_loop().run_in_executor(None, self._load_models)
        self._initialized = True
        logger.info(f"✅ STT ready — Local Whisper({settings.WHISPER_MODEL}) on {settings.DEVICE}")

    def _load_models(self):
        """Load models in thread pool to not block async loop."""
        from faster_whisper import WhisperModel
        self.model = WhisperModel(
            settings.WHISPER_MODEL,
            device=settings.DEVICE,
            compute_type=settings.COMPUTE_TYPE,
            cpu_threads=1,
            num_workers=1,
        )

    def is_speech(self, audio_chunk) -> bool:
        """Detect speech in a 100ms chunk using RMS energy threshold."""
        import numpy as np
        try:
            if audio_chunk is None or len(audio_chunk) == 0:
                return True
            max_val = np.max(np.abs(audio_chunk))
            if max_val > 1.0:
                audio_chunk = audio_chunk / 32768.0  # normalize int16
            rms = np.sqrt(np.mean(np.square(audio_chunk)))
            # Standard vocal presence RMS threshold (0.015)
            return rms > 0.015
        except Exception:
            return True

    def _pcm_to_wav(self, pcm_bytes: bytes, sample_rate: int = 16000) -> bytes:
        """Wrap raw PCM16 bytes in WAV headers in-memory for cloud API compatibility."""
        import wave
        
        # Check if already has a WAV header (RIFF...)
        if pcm_bytes.startswith(b"RIFF"):
            return pcm_bytes
            
        wav_buf = io.BytesIO()
        with wave.open(wav_buf, "wb") as wav_file:
            wav_file.setnchannels(1)  # Mono
            wav_file.setsampwidth(2)   # 2 bytes per sample (16-bit)
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(pcm_bytes)
        return wav_buf.getvalue()

    async def _transcribe_groq(self, wav_bytes: bytes, language: Optional[str] = None) -> tuple[str, str]:
        """Transcribe audio using Groq Whisper Cloud API."""
        import httpx
        
        url = "https://api.groq.com/openai/v1/audio/transcriptions"
        headers = {"Authorization": f"Bearer {settings.GROQ_API_KEY}"}
        
        files = {
            "file": ("audio.wav", wav_bytes, "audio/wav")
        }
        data = {
            "model": "whisper-large-v3",
        }
        if language and language != "auto":
            data["language"] = language

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(url, headers=headers, files=files, data=data)
            response.raise_for_status()
            res = response.json()
            text = res.get("text", "").strip()
            return text, language or "en"

    async def _transcribe_openai(self, wav_bytes: bytes, language: Optional[str] = None) -> tuple[str, str]:
        """Transcribe audio using OpenAI Whisper Cloud API."""
        import httpx
        
        url = "https://api.openai.com/v1/audio/transcriptions"
        headers = {"Authorization": f"Bearer {settings.OPENAI_API_KEY}"}
        
        files = {
            "file": ("audio.wav", wav_bytes, "audio/wav")
        }
        data = {
            "model": "whisper-1",
        }
        if language and language != "auto":
            data["language"] = language

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(url, headers=headers, files=files, data=data)
            response.raise_for_status()
            res = response.json()
            text = res.get("text", "").strip()
            return text, language or "en"

    async def transcribe(
        self,
        audio_bytes: bytes,
        language: Optional[str] = None,
    ) -> dict:
        """
        Transcribe audio bytes to text.
        Returns: {"text": str, "language": str, "latency_ms": float}
        """
        await self.initialize()
        start = time.perf_counter()

        provider = settings.STT_PROVIDER.lower()
        wav_bytes = self._pcm_to_wav(audio_bytes, settings.SAMPLE_RATE)
        
        text = ""
        detected_lang = language or "en"
        used_api = False

        if provider == "groq" and settings.GROQ_API_KEY:
            try:
                text, detected_lang = await self._transcribe_groq(wav_bytes, language)
                used_api = True
            except Exception as e:
                logger.warning(f"⚠️ Groq STT failed: {e}. Falling back to local Whisper.")

        elif provider == "openai" and settings.OPENAI_API_KEY:
            try:
                text, detected_lang = await self._transcribe_openai(wav_bytes, language)
                used_api = True
            except Exception as e:
                logger.warning(f"⚠️ OpenAI STT failed: {e}. Falling back to local Whisper.")

        if not used_api:
            # Lazy-load local Whisper models if fallback occurs
            if not self.model:
                logger.info("🔄 Lazy-loading local faster-whisper as fallback...")
                await asyncio.get_event_loop().run_in_executor(None, self._load_models)

            def _do_transcribe():
                audio_np = self._bytes_to_numpy(audio_bytes)
                segments, info = self.model.transcribe(
                    audio_np,
                    language=language if language != "auto" else None,
                    beam_size=3,            # optimized beam size
                    best_of=3,
                    vad_filter=True,
                    vad_parameters=dict(
                        min_silence_duration_ms=300,
                        speech_pad_ms=100,
                    ),
                    word_timestamps=False,
                )
                res_text = " ".join(s.text.strip() for s in segments)
                res_lang = info.language if language == "auto" else (language or "en")
                return res_text.strip(), res_lang

            text, detected_lang = await asyncio.get_event_loop().run_in_executor(
                None, _do_transcribe
            )

        latency = (time.perf_counter() - start) * 1000

        return {
            "text": text,
            "language": detected_lang,
            "latency_ms": round(latency, 1),
        }

    def _bytes_to_numpy(self, audio_bytes: bytes):
        """Convert raw audio bytes (PCM16 or WAV) to float32 numpy array."""
        import numpy as np
        try:
            # Try WAV format first
            with io.BytesIO(audio_bytes) as buf:
                import soundfile as sf
                data, _ = sf.read(buf, dtype="float32")
                if data.ndim > 1:
                    data = data.mean(axis=1)  # mono
                return data
        except Exception:
            # Fallback: treat as raw PCM int16
            audio_np = np.frombuffer(audio_bytes, dtype=np.int16).astype(np.float32)
            return audio_np / 32768.0

    async def stream_transcribe(
        self,
        audio_chunks: list[bytes],
        language: Optional[str] = None,
    ) -> dict:
        """
        Transcribe multiple buffered chunks.
        Chunks are 100ms PCM segments buffered by VAD logic.
        """
        if not audio_chunks:
            return {"text": "", "language": language or "en", "latency_ms": 0}

        combined = b"".join(audio_chunks)
        return await self.transcribe(combined, language)


# Singleton instance
stt_service = STTService()
