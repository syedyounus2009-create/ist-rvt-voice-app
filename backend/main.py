"""
IST-RVT — Main FastAPI Application
Real-Time Voice Translator Backend
"""

import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse

from config import settings
from database import init_db
from routers import auth, translate, calls, contacts
from websocket.audio_handler import audio_websocket_handler
from websocket.signaling_handler import signaling_websocket_handler
from services.room_manager import room_manager
from services.stt_service import stt_service
from services.translation_service import translation_service

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("IST-RVT")

# ── Startup / Shutdown ────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🚀 IST-RVT Backend starting...")
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)

    # Init database
    await init_db()

    # Pre-warm AI models in background (non-blocking)
    asyncio.create_task(_warm_models())

    logger.info(f"✅ IST-RVT v{settings.APP_VERSION} ready on port {settings.PORT}")
    yield

    logger.info("👋 IST-RVT shutting down...")


async def _warm_models():
    """Pre-load AI models so first request is fast."""
    try:
        await asyncio.sleep(2)  # Let server fully start first
        logger.info("🔥 Pre-warming STT model...")
        await stt_service.initialize()
        logger.info("🔥 Pre-warming translation service...")
        await translation_service.initialize()
        logger.info("✅ All models warmed up")
    except Exception as e:
        logger.warning(f"⚠️ Model warm-up partial failure: {e}")


# ── App Initialization ────────────────────────────────────────────────────────

app = FastAPI(
    title="IST-RVT API",
    description="Real-Time Voice Translator — IST-RVT Backend",
    version=settings.APP_VERSION,
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# Global CORS Configuration — Allows Flutter Web (any port) to connect smoothly
# In main.py around line 68:
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 👈 Change this from settings.CORS_ORIGINS to ["*"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# GZipMiddleware removed as it breaks WebSockets on Render

# Static files (uploads)
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Serve Flutter Web App
web_dir = os.path.join(os.path.dirname(__file__), "web")
if os.path.exists(web_dir):
    app.mount("/web", StaticFiles(directory=web_dir, html=True), name="web")
    logger.info("🌐 Serving Flutter Web app at /web")
else:
    logger.warning("⚠️ Flutter Web app directory not found at ./web")

# ── REST Routers ──────────────────────────────────────────────────────────────

app.include_router(auth.router, prefix="/api/v1")
app.include_router(translate.router, prefix="/api/v1")
app.include_router(calls.router, prefix="/api/v1")
app.include_router(contacts.router, prefix="/api/v1")


# ── WebSocket Endpoints ───────────────────────────────────────────────────────

@app.websocket("/ws/audio/{room_id}")
async def audio_ws(
    websocket: WebSocket,
    room_id: str,
    user_id: str = Query(...),
    source_lang: str = Query("en"),
    target_lang: str = Query("ar"),
):
    """
    Real-time audio translation WebSocket.
    Connect: ws://host/ws/audio/{room_id}?user_id=X&source_lang=en&target_lang=ar
    """
    await audio_websocket_handler(websocket, room_id, user_id, source_lang, target_lang)


@app.websocket("/ws/signal/{room_id}")
async def signal_ws(
    websocket: WebSocket,
    room_id: str,
    user_id: str = Query(...),
):
    """
    WebRTC signaling WebSocket for P2P call setup.
    """
    await signaling_websocket_handler(websocket, room_id, user_id)


# ── Health & Admin Endpoints ──────────────────────────────────────────────────

@app.get("/")
async def root():
    return {
        "app": "IST-RVT",
        "version": settings.APP_VERSION,
        "status": "running",
        "tagline": "Real-Time Voice Translation — Speak Any Language",
    }


@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "stt_ready": stt_service._initialized,
        "translation_ready": translation_service._argos_ready,
        "active_rooms": room_manager.stats()["active_rooms"],
        "timestamp": int(time.time()),
    }


@app.get("/api/v1/admin/stats")
async def admin_stats():
    """Admin dashboard statistics endpoint."""
    room_stats = room_manager.stats()
    return {
        "active_rooms": room_stats["active_rooms"],
        "total_connections": room_manager.total_connections,
        "rooms": room_stats["rooms"],
        "online_users": len(room_manager.online_users()),
        "stt_model": settings.WHISPER_MODEL,
        "device": settings.DEVICE,
        "tts_engine": settings.TTS_ENGINE,
        "version": settings.APP_VERSION,
    }


@app.get("/api/v1/admin/languages")
async def admin_languages():
    from services.translation_service import EDGE_TTS_VOICES
    return {
        "supported": settings.SUPPORTED_LANGUAGES,
        "tts_voices": EDGE_TTS_VOICES,
        "installed_pairs": [
            f"{s}→{t}" for s, t in translation_service._installed_pairs
        ],
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        ws_ping_interval=20,
        ws_ping_timeout=30,
    )