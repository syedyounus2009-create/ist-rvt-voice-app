"""
IST-RVT WebSocket Room Manager
Manages active rooms for calls and real-time translation sessions.
Falls back to in-memory store if Redis is unavailable.
"""

import asyncio
import json
import logging
import time
from typing import Optional
from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionInfo:
    def __init__(self, websocket: WebSocket, user_id: str, role: str = "user"):
        self.websocket = websocket
        self.user_id = user_id
        self.role = role
        self.connected_at = time.time()
        self.is_alive = True


class Room:
    def __init__(self, room_id: str, room_type: str = "audio"):
        self.room_id = room_id
        self.room_type = room_type  # "audio", "signal", "chat"
        self.connections: dict[str, ConnectionInfo] = {}
        self.created_at = time.time()
        self.metadata: dict = {}

    def add(self, user_id: str, conn: ConnectionInfo):
        self.connections[user_id] = conn

    def remove(self, user_id: str):
        self.connections.pop(user_id, None)

    @property
    def count(self) -> int:
        return len(self.connections)

    @property
    def is_empty(self) -> bool:
        return self.count == 0

    async def broadcast(self, message: dict | bytes, exclude_user: Optional[str] = None):
        """Send message to all connected users in this room."""
        dead = []
        for uid, conn in self.connections.items():
            if uid == exclude_user:
                continue
            try:
                if isinstance(message, bytes):
                    await conn.websocket.send_bytes(message)
                else:
                    await conn.websocket.send_json(message)
            except Exception:
                dead.append(uid)
        for uid in dead:
            self.remove(uid)

    async def send_to(self, user_id: str, message: dict | bytes):
        """Send message to a specific user."""
        conn = self.connections.get(user_id)
        if not conn:
            return
        try:
            if isinstance(message, bytes):
                await conn.websocket.send_bytes(message)
            else:
                await conn.websocket.send_json(message)
        except Exception:
            self.remove(user_id)

    def get_participants(self) -> list[str]:
        return list(self.connections.keys())


class RoomManager:
    def __init__(self):
        self._rooms: dict[str, Room] = {}
        self._user_rooms: dict[str, set[str]] = {}  # user_id → set of room_ids
        # Global stats
        self.total_connections = 0
        self.total_messages = 0

    def get_or_create(self, room_id: str, room_type: str = "audio") -> Room:
        if room_id not in self._rooms:
            self._rooms[room_id] = Room(room_id, room_type)
            logger.info(f"📢 Room created: {room_id} ({room_type})")
        return self._rooms[room_id]

    def get(self, room_id: str) -> Optional[Room]:
        return self._rooms.get(room_id)

    async def connect(
        self,
        room_id: str,
        user_id: str,
        websocket: WebSocket,
        room_type: str = "audio",
    ) -> Room:
        await websocket.accept()
        room = self.get_or_create(room_id, room_type)
        conn = ConnectionInfo(websocket, user_id)
        room.add(user_id, conn)
        self._user_rooms.setdefault(user_id, set()).add(room_id)
        self.total_connections += 1
        logger.info(f"🔗 {user_id} joined room {room_id} ({room.count} total)")
        return room

    async def disconnect(self, room_id: str, user_id: str):
        room = self._rooms.get(room_id)
        if room:
            room.remove(user_id)
            logger.info(f"🔌 {user_id} left room {room_id} ({room.count} remaining)")
            if room.is_empty:
                del self._rooms[room_id]
                logger.info(f"🗑️ Room {room_id} destroyed (empty)")
        if user_id in self._user_rooms:
            self._user_rooms[user_id].discard(room_id)

    def stats(self) -> dict:
        return {
            "active_rooms": len(self._rooms),
            "total_connections": self.total_connections,
            "rooms": [
                {
                    "id": rid,
                    "type": r.room_type,
                    "participants": r.count,
                    "age_seconds": int(time.time() - r.created_at),
                }
                for rid, r in self._rooms.items()
            ],
        }

    def online_users(self) -> list[str]:
        return list(self._user_rooms.keys())


# Singleton
room_manager = RoomManager()
