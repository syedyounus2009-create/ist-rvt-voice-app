"""
IST-RVT TTS Service
- Primary: Microsoft Edge TTS (free, 300+ voices, no API key, high quality)
- Voice Preservation: Pitch/formant shifting to match user's voice profile
- Optional: XTTS-v2 voice cloning (GPU recommended)
- Fallback: gTTS (Google)
"""

import asyncio
import io
import logging
import time
import tempfile
import os
from typing import Optional
from config import settings

logger = logging.getLogger(__name__)


class TTSService:
    def __init__(self):
        self._xtts_model = None
        self._speaker_embeddings: dict = {}
        self._voice_profiles: dict[str, dict] = {}  # pitch/speed profiles per user

    async def synthesize(
        self,
        text: str,
        language: str,
        user_id: Optional[str] = None,
        voice_name: Optional[str] = None,
    ) -> dict:
        """
        Convert text to speech audio bytes.
        Returns: {"audio": bytes, "format": "wav", "latency_ms": float, "engine": str}
        """
        if not text.strip():
            return {"audio": b"", "format": "wav", "latency_ms": 0, "engine": "none"}

        start = time.perf_counter()

        # Determine engine
        if settings.VOICE_CLONE_ENABLED and user_id and user_id in self._speaker_embeddings:
            audio, engine = await self._xtts_synthesize(text, language, user_id)
        else:
            audio, engine = await self._edge_tts_synthesize(text, language, voice_name)

        # Apply voice profile (pitch/speed matching) if available
        if user_id and user_id in self._voice_profiles and engine != "xtts":
            audio = await self._apply_voice_profile(audio, self._voice_profiles[user_id])

        latency = (time.perf_counter() - start) * 1000
        return {
            "audio": audio,
            "format": "wav",
            "latency_ms": round(latency, 1),
            "engine": engine,
        }

    async def _edge_tts_synthesize(
        self, text: str, language: str, voice_name: Optional[str] = None
    ) -> tuple[bytes, str]:
        """Microsoft Edge TTS — free, high quality, 300+ voices."""
        try:
            import edge_tts
            from services.translation_service import EDGE_TTS_VOICES

            voice = voice_name or EDGE_TTS_VOICES.get(language, "en-US-AriaNeural")

            def _run():
                import asyncio as _asyncio
                async def _inner():
                    communicate = edge_tts.Communicate(text, voice)
                    audio_data = b""
                    async for chunk in communicate.stream():
                        if chunk["type"] == "audio":
                            audio_data += chunk["data"]
                    return audio_data

                loop = _asyncio.new_event_loop()
                try:
                    return loop.run_until_complete(_inner())
                finally:
                    loop.close()

            audio = await asyncio.get_event_loop().run_in_executor(None, _run)
            # Convert mp3 → wav
            audio = self._mp3_to_wav(audio)
            return audio, "edge_tts"

        except Exception as e:
            logger.warning(f"Edge TTS failed: {e}, falling back to gTTS")
            return await self._gtts_synthesize(text, language)

    async def _gtts_synthesize(self, text: str, language: str) -> tuple[bytes, str]:
        """Google TTS fallback."""
        try:
            from gtts import gTTS
            def _run():
                buf = io.BytesIO()
                tts = gTTS(text=text, lang=language, slow=False)
                tts.write_to_fp(buf)
                buf.seek(0)
                return buf.read()

            mp3_bytes = await asyncio.get_event_loop().run_in_executor(None, _run)
            audio = self._mp3_to_wav(mp3_bytes)
            return audio, "gtts"
        except Exception as e:
            logger.error(f"gTTS failed: {e}")
            return b"", "error"

    async def _xtts_synthesize(
        self, text: str, language: str, user_id: str
    ) -> tuple[bytes, str]:
        """XTTS-v2 voice cloning (GPU recommended)."""
        try:
            embedding = self._speaker_embeddings.get(user_id)
            if embedding is None:
                return await self._edge_tts_synthesize(text, language)

            def _run():
                from TTS.api import TTS
                if self._xtts_model is None:
                    self._xtts_model = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
                buf = io.BytesIO()
                self._xtts_model.tts_to_file(
                    text=text,
                    language=language,
                    speaker_embedding=embedding,
                    file_path=buf,
                )
                buf.seek(0)
                return buf.read()

            audio = await asyncio.get_event_loop().run_in_executor(None, _run)
            return audio, "xtts_v2"
        except Exception as e:
            logger.warning(f"XTTS failed: {e}")
            return await self._edge_tts_synthesize(text, language)

    async def extract_voice_profile(self, user_id: str, audio_bytes: bytes):
        """
        Extract voice pitch/speed profile from user's voice sample (3+ seconds).
        Used for lightweight voice preservation without GPU.
        """
        def _extract():
            try:
                import numpy as np
                import librosa
                audio_np, sr = librosa.load(io.BytesIO(audio_bytes), sr=22050, mono=True)
                # Extract fundamental frequency (pitch)
                f0, _, _ = librosa.pyin(
                    audio_np, fmin=librosa.note_to_hz("C2"),
                    fmax=librosa.note_to_hz("C7"), sr=sr
                )
                valid_f0 = f0[~np.isnan(f0)] if f0 is not None else np.array([220.0])
                mean_pitch = float(np.median(valid_f0)) if len(valid_f0) > 0 else 220.0
                # Speaking rate estimation
                tempo, _ = librosa.beat.beat_track(y=audio_np, sr=sr)
                self._voice_profiles[user_id] = {
                    "mean_pitch_hz": mean_pitch,
                    "tempo": float(tempo),
                }
                logger.info(f"✅ Voice profile extracted for {user_id}: pitch={mean_pitch:.1f}Hz")
            except Exception as e:
                logger.warning(f"Voice profile extraction failed: {e}")

        await asyncio.get_event_loop().run_in_executor(None, _extract)

    async def _apply_voice_profile(self, audio_bytes: bytes, profile: dict) -> bytes:
        """Apply pitch shifting to match user's voice profile."""
        if not audio_bytes:
            return audio_bytes
        def _shift():
            try:
                import numpy as np
                import librosa
                import soundfile as sf
                audio_np, sr = librosa.load(io.BytesIO(audio_bytes), sr=22050, mono=True)
                # Target pitch from user profile
                target_pitch = profile.get("mean_pitch_hz", 220.0)
                # Estimate current TTS pitch (neutral ~200Hz for female voices)
                current_pitch = 200.0
                if current_pitch > 0 and target_pitch > 0:
                    semitones = 12 * np.log2(target_pitch / current_pitch)
                    semitones = np.clip(semitones, -6, 6)  # max ±6 semitones
                    audio_np = librosa.effects.pitch_shift(audio_np, sr=sr, n_steps=semitones)
                buf = io.BytesIO()
                sf.write(buf, audio_np, sr, format="WAV")
                return buf.getvalue()
            except Exception as e:
                logger.warning(f"Pitch shift failed: {e}")
                return audio_bytes

        return await asyncio.get_event_loop().run_in_executor(None, _shift)

    def _mp3_to_wav(self, mp3_bytes: bytes) -> bytes:
        """Convert MP3 bytes to WAV bytes."""
        try:
            from pydub import AudioSegment
            seg = AudioSegment.from_mp3(io.BytesIO(mp3_bytes))
            buf = io.BytesIO()
            seg.export(buf, format="wav")
            return buf.getvalue()
        except Exception:
            return mp3_bytes  # Return as-is if conversion fails


# Singleton
tts_service = TTSService()
