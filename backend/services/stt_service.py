"""
IST-RVT Speech-to-Text Service
- faster-whisper with int8 quantization (CPU-optimized)
- Silero VAD for millisecond speech detection
- 100ms chunk streaming with smart buffering
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
        self.vad_model = None
        self.vad_utils = None
        self._initialized = False

    async def initialize(self):
        """Lazy-load models on first use."""
        if self._initialized:
            return
        logger.info("🔄 Loading faster-whisper model...")
        await asyncio.get_event_loop().run_in_executor(None, self._load_models)
        self._initialized = True
        logger.info(f"✅ STT ready — Whisper({settings.WHISPER_MODEL}) on {settings.DEVICE}")

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

        def _do_transcribe():
            audio_np = self._bytes_to_numpy(audio_bytes)
            segments, info = self.model.transcribe(
                audio_np,
                language=language if language != "auto" else None,
                beam_size=3,            # faster than default 5
                best_of=3,
                vad_filter=True,        # built-in VAD filter
                vad_parameters=dict(
                    min_silence_duration_ms=300,
                    speech_pad_ms=100,
                ),
                word_timestamps=False,
            )
            text = " ".join(s.text.strip() for s in segments)
            detected_lang = info.language if language == "auto" else (language or "en")
            return text.strip(), detected_lang

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
            import soundfile as sf
            # Try WAV format first
            with io.BytesIO(audio_bytes) as buf:
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

        # Concatenate all chunks into one audio buffer
        combined = b"".join(audio_chunks)
        return await self.transcribe(combined, language)


# Singleton instance
stt_service = STTService()
