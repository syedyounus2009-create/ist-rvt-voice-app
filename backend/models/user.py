"""
IST-RVT User Model
"""

from sqlalchemy import Column, String, Boolean, DateTime, Integer, Text
from sqlalchemy.sql import func
from database import Base
import uuid


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    phone = Column(String(20), unique=True, nullable=True)
    hashed_password = Column(String, nullable=False)
    display_name = Column(String(100), nullable=True)
    avatar_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    is_online = Column(Boolean, default=False)
    preferred_language = Column(String(10), default="en")
    target_language = Column(String(10), default="ar")
    # Voice sample path for voice cloning
    voice_sample_path = Column(String, nullable=True)
    # Speaker embedding cache path
    speaker_embedding_path = Column(String, nullable=True)
    # Stats
    total_calls = Column(Integer, default=0)
    total_translations = Column(Integer, default=0)
    total_minutes = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_seen = Column(DateTime(timezone=True), onupdate=func.now())
    # Settings
    settings_json = Column(Text, default="{}")
