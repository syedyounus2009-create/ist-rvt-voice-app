"""
IST-RVT WebRTC Signaling WebSocket Handler
Handles SDP offer/answer and ICE candidate exchange for P2P calls.
"""

import asyncio
import json
import logging
from fastapi import WebSocket, WebSocketDisconnect
from services.room_manager import room_manager

logger = logging.getLogger(__name__)


async def signaling_websocket_handler(
    websocket: WebSocket,
    room_id: str,
    user_id: str,
):
    """
    WebRTC Signaling WebSocket.
    Protocol:
      {"type": "offer", "sdp": ..., "target_user": ...}
      {"type": "answer", "sdp": ..., "target_user": ...}
      {"type": "ice_candidate", "candidate": ..., "target_user": ...}
      {"type": "call_request", "call_type": "voice"|"video", "from_user": ...}
      {"type": "call_accept"|"call_reject", "room_id": ...}
      {"type": "call_end", "room_id": ...}
    """
    room = await room_manager.connect(room_id, user_id, websocket, "signal")

    await websocket.send_json({
        "type": "joined",
        "room_id": room_id,
        "user_id": user_id,
        "participants": room.get_participants(),
    })

    # Notify others that user joined
    await room.broadcast(
        {"type": "peer_joined", "user_id": user_id, "participants": room.get_participants()},
        exclude_user=user_id,
    )

    try:
        while True:
            try:
                message = await asyncio.wait_for(websocket.receive(), timeout=60.0)
            except asyncio.TimeoutError:
                await websocket.send_json({"type": "ping"})
                continue

            if message["type"] == "websocket.disconnect":
                break

            if "text" not in message or not message["text"]:
                continue

            try:
                data = json.loads(message["text"])
            except json.JSONDecodeError:
                continue

            msg_type = data.get("type", "")
            target_user = data.get("target_user")

            # ── WebRTC signaling ──────────────────────────────────────────
            if msg_type in ("offer", "answer", "ice_candidate"):
                data["from_user"] = user_id
                if target_user:
                    await room.send_to(target_user, data)
                else:
                    await room.broadcast(data, exclude_user=user_id)

            # ── Call control ──────────────────────────────────────────────
            elif msg_type == "call_request":
                data["from_user"] = user_id
                data["room_id"] = room_id
                if target_user:
                    await room.send_to(target_user, data)
                else:
                    await room.broadcast(data, exclude_user=user_id)

            elif msg_type in ("call_accept", "call_reject", "call_end", "call_busy"):
                data["from_user"] = user_id
                if target_user:
                    await room.send_to(target_user, data)
                else:
                    await room.broadcast(data, exclude_user=user_id)

            # ── Chat messages ─────────────────────────────────────────────
            elif msg_type == "chat_message":
                data["from_user"] = user_id
                await room.broadcast(data, exclude_user=user_id)

            # ── Presence ──────────────────────────────────────────────────
            elif msg_type == "ping":
                await websocket.send_json({"type": "pong"})

            elif msg_type == "participants":
                await websocket.send_json({
                    "type": "participants",
                    "participants": room.get_participants(),
                    "count": room.count,
                })

    except WebSocketDisconnect:
        logger.info(f"📴 Signal disconnect: {user_id} from {room_id}")
    except Exception as e:
        logger.error(f"❌ Signal WS error [{room_id}/{user_id}]: {e}")
    finally:
        await room_manager.disconnect(room_id, user_id)
        # Notify others
        remaining_room = room_manager.get(room_id)
        if remaining_room:
            await remaining_room.broadcast(
                {"type": "peer_left", "user_id": user_id,
                 "participants": remaining_room.get_participants()},
            )
