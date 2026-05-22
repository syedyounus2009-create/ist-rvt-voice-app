"""
IST-RVT Calls Router — Call initiation, history, management
"""

import uuid
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models.session import CallSession
from models.user import User
from routers.auth import get_current_user
from services.room_manager import room_manager

router = APIRouter(prefix="/calls", tags=["Calls"])


class InitiateCallRequest(BaseModel):
    target_user_id: str
    call_type: str = "voice"   # voice, video
    source_language: str = "en"
    target_language: str = "ar"
    voice_clone_enabled: bool = False


class CallResponse(BaseModel):
    room_id: str
    call_type: str
    status: str
    source_language: str
    target_language: str
    ws_audio_url: str
    ws_signal_url: str


class CallHistoryItem(BaseModel):
    id: str
    room_id: str
    call_type: str
    status: str
    source_language: str
    target_language: str
    duration_seconds: int
    total_translations: int
    avg_latency_ms: float
    started_at: datetime
    ended_at: Optional[datetime]


@router.post("/initiate", response_model=CallResponse)
async def initiate_call(
    data: InitiateCallRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Initiate a new call — returns room ID and WebSocket URLs."""
    room_id = str(uuid.uuid4())

    session = CallSession(
        room_id=room_id,
        initiator_id=current_user.id,
        call_type=data.call_type,
        status="pending",
        source_language=data.source_language,
        target_language=data.target_language,
        voice_clone_enabled=data.voice_clone_enabled,
        participant_ids=f"{current_user.id},{data.target_user_id}",
    )
    db.add(session)

    # Update user stats
    current_user.total_calls += 1
    await db.commit()

    return CallResponse(
        room_id=room_id,
        call_type=data.call_type,
        status="pending",
        source_language=data.source_language,
        target_language=data.target_language,
        ws_audio_url=f"/ws/audio/{room_id}",
        ws_signal_url=f"/ws/signal/{room_id}",
    )


@router.post("/{room_id}/end")
async def end_call(
    room_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """End an active call and record stats."""
    result = await db.execute(select(CallSession).where(CallSession.room_id == room_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(404, "Call session not found")

    # Get pipeline stats
    from services.voice_pipeline import pipeline_manager
    pipeline = pipeline_manager.get(room_id)
    if pipeline:
        session.total_translations = pipeline.total_translations
        session.avg_latency_ms = pipeline.avg_latency_ms
        pipeline_manager.destroy(room_id)

    session.status = "ended"
    session.ended_at = datetime.utcnow()
    if session.started_at:
        session.duration_seconds = int(
            (session.ended_at - session.started_at).total_seconds()
        )
        current_user.total_minutes += session.duration_seconds // 60

    await db.commit()
    return {"message": "Call ended", "duration_seconds": session.duration_seconds}


@router.get("/history", response_model=List[CallHistoryItem])
async def call_history(
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get call history for the current user."""
    result = await db.execute(
        select(CallSession)
        .where(CallSession.participant_ids.contains(current_user.id))
        .order_by(desc(CallSession.started_at))
        .limit(limit)
    )
    sessions = result.scalars().all()
    return [
        CallHistoryItem(
            id=s.id,
            room_id=s.room_id,
            call_type=s.call_type,
            status=s.status,
            source_language=s.source_language,
            target_language=s.target_language,
            duration_seconds=s.duration_seconds,
            total_translations=s.total_translations,
            avg_latency_ms=s.avg_latency_ms,
            started_at=s.started_at,
            ended_at=s.ended_at,
        )
        for s in sessions
    ]


@router.get("/active")
async def active_calls(current_user: User = Depends(get_current_user)):
    """Get currently active rooms/calls."""
    stats = room_manager.stats()
    return {
        "active_rooms": stats["active_rooms"],
        "rooms": stats["rooms"],
    }
