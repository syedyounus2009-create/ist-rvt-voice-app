"""
IST-RVT Message Model — supports text, voice, translated messages
"""

from sqlalchemy import Column, String, Boolean, DateTime, Text, Float
from sqlalchemy.sql import func
from database import Base
import uuid


class Message(Base):
    __tablename__ = "messages"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    room_id = Column(String, nullable=False, index=True)
    sender_id = Column(String, nullable=False, index=True)
    receiver_id = Column(String, nullable=True)  # null for group messages

    # Content
    message_type = Column(String(20), default="text")  # text, voice, image, file
    content = Column(Text, nullable=True)               # original text
    translated_content = Column(Text, nullable=True)    # translated text
    source_language = Column(String(10), default="en")
    target_language = Column(String(10), default="ar")
    audio_url = Column(String, nullable=True)           # voice message URL
    translated_audio_url = Column(String, nullable=True)
    file_url = Column(String, nullable=True)
    duration_seconds = Column(Float, nullable=True)     # voice message duration

    # Status
    is_read = Column(Boolean, default=False)
    is_deleted = Column(Boolean, default=False)
    is_encrypted = Column(Boolean, default=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    edited_at = Column(DateTime(timezone=True), nullable=True)
