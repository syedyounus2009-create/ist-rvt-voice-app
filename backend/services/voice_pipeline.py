"""
IST-RVT Voice Pipeline
Full end-to-end pipeline: Audio In → VAD → STT → Translate → TTS → Audio Out
Target latency: < 350ms on CPU, < 150ms on GPU
"""

import asyncio
import logging
import time
from typing import Optional

from services.stt_service import stt_service
from services.translation_service import translation_service
from services.tts_service import tts_service
from config import settings

logger = logging.getLogger(__name__)


class VoicePipeline:
    """
    Manages per-session audio buffering and the full STT→MT→TTS pipeline.
    Each active call/session creates a VoicePipeline instance.
    """

    def __init__(self, session_id: str, source_lang: str, target_lang: str, user_id: Optional[str] = None):
        self.session_id = session_id
        self.source_lang = source_lang
        self.target_lang = target_lang
        self.user_id = user_id

        # Audio buffering
        self._audio_buffer: list[bytes] = []
        self._silence_count: int = 0
        self._speaking: bool = False
        self._min_chunks_before_transcribe = 8    # 8 × 100ms = 0.8s minimum
        self._max_silence_chunks = 5              # 5 × 100ms = 0.5s silence → flush

        # Stats
        self.total_translations = 0
        self.total_latency_ms = 0.0

    async def process_chunk(self, audio_chunk: bytes) -> Optional[dict]:
        """
        Process a single 100ms audio chunk.
        Returns translated result dict when a complete utterance is ready, else None.
        Result: {"original": str, "translated": str, "audio": bytes,
                 "source_lang": str, "target_lang": str, "latency_ms": float}
        """
        # Convert to numpy for VAD
        import numpy as np
        audio_np = np.frombuffer(audio_chunk, dtype=np.int16).astype(np.float32) / 32768.0

        is_speech = stt_service.is_speech(audio_np)

        if is_speech:
            self._audio_buffer.append(audio_chunk)
            self._silence_count = 0
            self._speaking = True
        else:
            if self._speaking:
                self._silence_count += 1
                self._audio_buffer.append(audio_chunk)  # include trailing silence

            # Flush buffer when silence detected after speech
            if (
                self._speaking
                and self._silence_count >= self._max_silence_chunks
                and len(self._audio_buffer) >= self._min_chunks_before_transcribe
            ):
                result = await self._flush_buffer()
                self._reset_buffer()
                return result

        # Force flush if buffer too large (> 10 seconds)
        if len(self._audio_buffer) > 100:
            result = await self._flush_buffer()
            self._reset_buffer()
            return result

        return None

    async def _flush_buffer(self) -> Optional[dict]:
        """Transcribe buffered audio, translate, synthesize."""
        if not self._audio_buffer:
            return None

        start = time.perf_counter()
        chunks = list(self._audio_buffer)

        # Step 1: STT
        stt_result = await stt_service.stream_transcribe(chunks, self.source_lang)
        original_text = stt_result.get("text", "").strip()
        logger.info(f"[{self.session_id}] STT Result: '{original_text}'")

        if not original_text:
            logger.warning(f"[{self.session_id}] STT returned empty text. Aborting pipeline.")
            return None

        # Step 2: Translate
        trans_result = await translation_service.translate(
            original_text, self.source_lang, self.target_lang
        )
        translated_text = trans_result.get("text", "").strip()
        logger.info(f"[{self.session_id}] MT Result: '{translated_text}'")

        if not translated_text:
            logger.warning(f"[{self.session_id}] Translation returned empty text. Aborting pipeline.")
            return None

        # Step 3: TTS (synthesize translated text in user's voice)
        tts_result = await tts_service.synthesize(
            translated_text, self.target_lang, self.user_id
        )

        total_latency = (time.perf_counter() - start) * 1000
        self.total_translations += 1
        self.total_latency_ms += total_latency

        logger.info(
            f"[{self.session_id}] '{original_text[:30]}' → '{translated_text[:30]}' "
            f"| {total_latency:.0f}ms "
            f"(STT:{stt_result['latency_ms']:.0f}ms "
            f"MT:{trans_result['latency_ms']:.0f}ms "
            f"TTS:{tts_result['latency_ms']:.0f}ms)"
        )

        return {
            "type": "translation",
            "original": original_text,
            "translated": translated_text,
            "audio": tts_result["audio"],
            "audio_format": tts_result["format"],
            "source_lang": self.source_lang,
            "target_lang": self.target_lang,
            "latency_ms": round(total_latency, 1),
            "stt_latency_ms": stt_result["latency_ms"],
            "mt_latency_ms": trans_result["latency_ms"],
            "tts_latency_ms": tts_result["latency_ms"],
            "tts_engine": tts_result["engine"],
            "session_id": self.session_id,
        }

    def _reset_buffer(self):
        self._audio_buffer.clear()
        self._silence_count = 0
        self._speaking = False

    async def translate_text_only(self, text: str) -> dict:
        """Direct text translation (for chat messages)."""
        return await translation_service.translate(text, self.source_lang, self.target_lang)

    @property
    def avg_latency_ms(self) -> float:
        if self.total_translations == 0:
            return 0.0
        return self.total_latency_ms / self.total_translations


class PipelineManager:
    """Manages multiple active VoicePipeline instances."""

    def __init__(self):
        self._pipelines: dict[str, VoicePipeline] = {}

    def create(
        self,
        session_id: str,
        source_lang: str,
        target_lang: str,
        user_id: Optional[str] = None,
    ) -> VoicePipeline:
        pipeline = VoicePipeline(session_id, source_lang, target_lang, user_id)
        self._pipelines[session_id] = pipeline
        return pipeline

    def get(self, session_id: str) -> Optional[VoicePipeline]:
        return self._pipelines.get(session_id)

    def destroy(self, session_id: str):
        self._pipelines.pop(session_id, None)

    def stats(self) -> dict:
        return {
            "active_pipelines": len(self._pipelines),
            "sessions": list(self._pipelines.keys()),
        }


# Singleton
pipeline_manager = PipelineManager()
