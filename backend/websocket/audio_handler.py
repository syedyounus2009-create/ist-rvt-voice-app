"""
IST-RVT Audio WebSocket Handler
Real-time audio streaming: receive 100ms chunks → VAD → STT → MT → TTS → send back
"""

import asyncio
import base64
import json
import logging
from typing import Optional
from fastapi import WebSocket, WebSocketDisconnect

from services.room_manager import room_manager
from services.voice_pipeline import pipeline_manager
from services.stt_service import stt_service
from services.tts_service import tts_service

logger = logging.getLogger(__name__)


async def audio_websocket_handler(
    websocket: WebSocket,
    room_id: str,
    user_id: str,
    source_lang: str = "en",
    target_lang: str = "ar",
):
    """
    Main audio WebSocket handler per connection.
    Protocol:
      Client → Server: binary PCM16 audio chunks (100ms @ 16kHz)
      Client → Server: JSON control messages {"type": "config"|"end_session"|"ping"}
      Server → Client: JSON {"type": "translation", "original": ..., "translated": ...,
                              "audio": <base64 wav>, "latency_ms": ...}
    """
    room = await room_manager.connect(room_id, user_id, websocket, "audio")

    # Ensure STT is initialized
    await stt_service.initialize()

    # Create pipeline for this user's session
    pipeline = pipeline_manager.create(
        session_id=f"{room_id}:{user_id}",
        source_lang=source_lang,
        target_lang=target_lang,
        user_id=user_id,
    )

    await websocket.send_json({
        "type": "connected",
        "room_id": room_id,
        "user_id": user_id,
        "source_lang": source_lang,
        "target_lang": target_lang,
        "message": "IST-RVT Audio stream ready ✅",
    })

    try:
        while True:
            try:
                # Receive either binary (audio) or text (control)
                message = await asyncio.wait_for(websocket.receive(), timeout=30.0)
            except asyncio.TimeoutError:
                # Send keepalive ping
                await websocket.send_json({"type": "ping"})
                continue

            if message["type"] == "websocket.disconnect":
                break

            # ── Binary audio chunk ────────────────────────────────────────
            if "bytes" in message and message["bytes"]:
                audio_chunk = message["bytes"]
                result = await pipeline.process_chunk(audio_chunk)

                if result and result.get("translated"):
                    # Send text result immediately
                    await websocket.send_json({
                        "type": "translation",
                        "original": result["original"],
                        "translated": result["translated"],
                        "source_lang": result["source_lang"],
                        "target_lang": result["target_lang"],
                        "latency_ms": result["latency_ms"],
                        "stt_latency_ms": result["stt_latency_ms"],
                        "mt_latency_ms": result["mt_latency_ms"],
                        "tts_latency_ms": result["tts_latency_ms"],
                        "tts_engine": result.get("tts_engine", ""),
                    })

                    # Send audio separately as binary (more efficient)
                    if result.get("audio"):
                        # Prepend 4-byte little-endian msg type marker: 0x01 = translated audio
                        audio_payload = b"\x01" + result["audio"]
                        await websocket.send_bytes(audio_payload)

                    # Broadcast translated text to other participants in room
                    await room.broadcast(
                        {
                            "type": "peer_translation",
                            "from_user": user_id,
                            "original": result["original"],
                            "translated": result["translated"],
                            "latency_ms": result["latency_ms"],
                        },
                        exclude_user=user_id,
                    )

            # ── JSON control messages ─────────────────────────────────────
            elif "text" in message and message["text"]:
                try:
                    ctrl = json.loads(message["text"])
                    msg_type = ctrl.get("type", "")

                    if msg_type == "config":
                        # Update language pair mid-session
                        new_src = ctrl.get("source_lang", source_lang)
                        new_tgt = ctrl.get("target_lang", target_lang)
                        pipeline_manager.destroy(f"{room_id}:{user_id}")
                        pipeline = pipeline_manager.create(
                            f"{room_id}:{user_id}", new_src, new_tgt, user_id
                        )
                        source_lang, target_lang = new_src, new_tgt
                        await websocket.send_json({
                            "type": "config_updated",
                            "source_lang": new_src,
                            "target_lang": new_tgt,
                        })

                    elif msg_type == "translate_text":
                        # Direct text translation (for chat)
                        text = ctrl.get("text", "")
                        if text:
                            result = await pipeline.translate_text_only(text)
                            await websocket.send_json({
                                "type": "text_translation",
                                "original": text,
                                "translated": result["text"],
                                "latency_ms": result["latency_ms"],
                            })

                    elif msg_type == "ping":
                        await websocket.send_json({"type": "pong"})

                    elif msg_type == "stats":
                        await websocket.send_json({
                            "type": "stats",
                            "total_translations": pipeline.total_translations,
                            "avg_latency_ms": round(pipeline.avg_latency_ms, 1),
                            "room_participants": room.count,
                        })

                    elif msg_type == "end_session":
                        break

                except json.JSONDecodeError:
                    pass

    except WebSocketDisconnect:
        logger.info(f"🔌 Client {user_id} disconnected from room {room_id}")
    except Exception as e:
        logger.error(f"❌ Audio WS error [{room_id}/{user_id}]: {e}")
    finally:
        pipeline_manager.destroy(f"{room_id}:{user_id}")
        await room_manager.disconnect(room_id, user_id)
        logger.info(f"🧹 Cleaned up session for {user_id} in {room_id}")
