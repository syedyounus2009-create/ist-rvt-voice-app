"""
IST-RVT Backend Configuration
Supports Railway, AWS, Azure, Render, and local deployment.
"""

import os
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # ─── App ─────────────────────────────────────────────────
    APP_NAME: str = "IST-RVT"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    # ─── Server ──────────────────────────────────────────────
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    # Allow all origins by default for mobile app (set specific in prod)
    CORS_ORIGINS: list = ["*"]

    # ─── Security ────────────────────────────────────────────
    SECRET_KEY: str = os.getenv("SECRET_KEY", "IST-RVT-secret-key-change-in-production-2026")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # ─── Database ────────────────────────────────────────────
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./ist_rvt.db")

    # ─── Redis (optional, falls back to in-memory if not set) ─
    REDIS_URL: Optional[str] = os.getenv("REDIS_URL", None)

    # ─── AI Models ───────────────────────────────────────────
    # STT: Options: tiny, base, small, medium, large-v2, large-v3
    WHISPER_MODEL: str = os.getenv("WHISPER_MODEL", "tiny")
    # Device: "cuda" if GPU available, otherwise "cpu"
    DEVICE: str = os.getenv("DEVICE", "cpu")
    # Compute type for faster-whisper (int8 for CPU, float16 for GPU)
    COMPUTE_TYPE: str = os.getenv("COMPUTE_TYPE", "int8")

    # ─── TTS ─────────────────────────────────────────────────
    # Options: "edge" (Microsoft, default), "gtts" (Google), "xtts" (voice clone, GPU)
    TTS_ENGINE: str = os.getenv("TTS_ENGINE", "edge")
    # Enable voice cloning (requires GPU + TTS==0.22.0 installed)
    VOICE_CLONE_ENABLED: bool = os.getenv("VOICE_CLONE_ENABLED", "false").lower() == "true"

    # ─── Audio Pipeline ──────────────────────────────────────
    # Audio chunk size in milliseconds for real-time streaming
    AUDIO_CHUNK_MS: int = int(os.getenv("AUDIO_CHUNK_MS", "100"))
    SAMPLE_RATE: int = 16000
    VAD_THRESHOLD: float = 0.5  # Silero VAD confidence threshold

    # ─── Supported Languages ─────────────────────────────────
    SUPPORTED_LANGUAGES: dict = {
        "en": "English",
        "ar": "Arabic",
        "zh": "Chinese",
        "ur": "Urdu",
        "fr": "French",
        "es": "Spanish",
        "de": "German",
        "hi": "Hindi",
        "tr": "Turkish",
        "pt": "Portuguese",
        "ru": "Russian",
        "ja": "Japanese",
        "ko": "Korean",
        "it": "Italian",
        "fa": "Persian",
    }

    # ─── File Storage ────────────────────────────────────────
    UPLOAD_DIR: str = "./uploads"
    MAX_AUDIO_SIZE_MB: int = 10

    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"


settings = Settings()
