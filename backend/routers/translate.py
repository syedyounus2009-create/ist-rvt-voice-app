"""
IST-RVT Translation REST Router
- Text translation endpoint
- Voice file upload → transcript + translation
- Supported languages list
"""

import io
import logging
from typing import Optional
from fastapi import APIRouter, Depends, File, Form, UploadFile, HTTPException
from pydantic import BaseModel

from routers.auth import get_current_user
from models.user import User
from services.translation_service import translation_service, EDGE_TTS_VOICES
from services.stt_service import stt_service
from services.tts_service import tts_service
from services.voice_pipeline import VoicePipeline
from config import settings

from fastapi.responses import Response

router = APIRouter(prefix="/translate", tags=["Translation"])
logger = logging.getLogger(__name__)


class TextTranslateRequest(BaseModel):
    text: str
    source_lang: str = "en"
    target_lang: str = "ar"
    synthesize: bool = False  # if True, also return TTS audio


class TextTranslateResponse(BaseModel):
    original: str
    translated: str
    source_lang: str
    target_lang: str
    engine: str
    latency_ms: float
    audio_base64: Optional[str] = None


@router.post("/text", response_model=TextTranslateResponse)
async def translate_text(
    request: TextTranslateRequest,
    current_user: User = Depends(get_current_user),
):
    """Translate text from source to target language."""
    result = await translation_service.translate(
        request.text, request.source_lang, request.target_lang
    )

    audio_b64 = None
    if request.synthesize and result["text"]:
        tts_result = await tts_service.synthesize(
            result["text"], request.target_lang, current_user.id
        )
        import base64
        audio_b64 = base64.b64encode(tts_result["audio"]).decode()

    return TextTranslateResponse(
        original=request.text,
        translated=result["text"],
        source_lang=request.source_lang,
        target_lang=request.target_lang,
        engine=result["engine"],
        latency_ms=result["latency_ms"],
        audio_base64=audio_b64,
    )


@router.post("/voice")
async def translate_voice(
    audio: UploadFile = File(...),
    source_lang: str = Form("en"),
    target_lang: str = Form("ar"),
    return_audio: bool = Form(True),
    current_user: User = Depends(get_current_user),
):
    """Upload audio file → transcribe → translate → optionally synthesize."""
    await stt_service.initialize()

    audio_bytes = await audio.read()
    if len(audio_bytes) > settings.MAX_AUDIO_SIZE_MB * 1024 * 1024:
        raise HTTPException(413, "Audio file too large")

    # STT
    stt_result = await stt_service.transcribe(audio_bytes, source_lang)
    original_text = stt_result["text"]

    if not original_text:
        return {"error": "No speech detected", "original": "", "translated": ""}

    # Translate
    trans_result = await translation_service.translate(original_text, source_lang, target_lang)
    translated_text = trans_result["text"]

    result = {
        "original": original_text,
        "translated": translated_text,
        "source_lang": source_lang,
        "target_lang": target_lang,
        "stt_latency_ms": stt_result["latency_ms"],
        "mt_latency_ms": trans_result["latency_ms"],
        "mt_engine": trans_result["engine"],
    }

    if return_audio and translated_text:
        tts_result = await tts_service.synthesize(
            translated_text, target_lang, current_user.id
        )
        import base64
        result["audio_base64"] = base64.b64encode(tts_result["audio"]).decode()
        result["tts_latency_ms"] = tts_result["latency_ms"]
        result["tts_engine"] = tts_result["engine"]

    return result


@router.post("/voice-profile")
async def upload_voice_profile(
    audio: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Upload 3–10 second voice sample to enable voice preservation."""
    audio_bytes = await audio.read()
    await tts_service.extract_voice_profile(current_user.id, audio_bytes)
    return {"message": "Voice profile saved. Your translated voice will now match your voice!"}


@router.get("/languages")
async def get_languages():
    """Get all supported languages."""
    return {
        "languages": [
            {
                "code": code,
                "name": name,
                "tts_voice": EDGE_TTS_VOICES.get(code, "en-US-AriaNeural"),
            }
            for code, name in settings.SUPPORTED_LANGUAGES.items()
        ]
    }


@router.get("/detect")
async def detect_language(text: str, current_user: User = Depends(get_current_user)):
    """Detect language of given text."""
    try:
        from deep_translator import GoogleTranslator
        detected = GoogleTranslator(source="auto", target="en").translate(text)
        return {"detected": "auto", "translated_sample": detected}
    except Exception:
        return {"detected": "unknown"}
