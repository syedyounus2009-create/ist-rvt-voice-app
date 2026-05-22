"""
IST-RVT Call Session Model
"""

from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Text
from sqlalchemy.sql import func
from database import Base
import uuid


class CallSession(Base):
    __tablename__ = "call_sessions"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    room_id = Column(String, unique=True, nullable=False, index=True)
    initiator_id = Column(String, nullable=False)
    call_type = Column(String(20), default="voice")  # voice, video, group
    status = Column(String(20), default="pending")   # pending, active, ended, missed
    source_language = Column(String(10), default="en")
    target_language = Column(String(10), default="ar")
    voice_clone_enabled = Column(Boolean, default=False)

    # Participants (comma-separated user IDs for group calls)
    participant_ids = Column(Text, default="")

    # Stats
    duration_seconds = Column(Integer, default=0)
    total_translations = Column(Integer, default=0)
    avg_latency_ms = Column(Float, default=0.0)

    # Transcript
    transcript_url = Column(String, nullable=True)

    started_at = Column(DateTime(timezone=True), server_default=func.now())
    ended_at = Column(DateTime(timezone=True), nullable=True)
