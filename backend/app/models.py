import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Boolean, Integer, BigInteger, 
    Numeric, Text, DateTime, ForeignKey, Index
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone_number = Column(String(16), unique=True, nullable=False, index=True)
    firebase_uid = Column(String(128), unique=True, nullable=False, index=True)
    carrier = Column(String(16), default="other")
    forwarding_status = Column(String(16), default="unverified")
    custom_greeting_url = Column(Text, nullable=True)
    consent_given_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    consent_version = Column(String(16), default="v1.0", nullable=False)
    data_retention_days = Column(Integer, default=30, nullable=False)
    status = Column(String(16), default="active")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    devices = relationship("UserDevice", back_populates="user", cascade="all, delete-orphan")
    voicemails = relationship("Voicemail", back_populates="user", cascade="all, delete-orphan")

class UserDevice(Base):
    __tablename__ = "user_devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    fcm_token = Column(Text, nullable=False)
    device_model = Column(String(64), nullable=True)
    os_version = Column(String(32), nullable=True)
    app_version = Column(String(32), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="devices")

class Voicemail(Base):
    __tablename__ = "voicemails"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    caller_number = Column(String(16), nullable=False)
    call_session_id = Column(String(128), unique=True, nullable=False, index=True)
    audio_path = Column(Text, nullable=False)
    audio_duration_seconds = Column(Integer, default=0, nullable=False)
    audio_file_size_bytes = Column(BigInteger, default=0)
    status = Column(String(16), default="recording", nullable=False)
    is_read = Column(Boolean, default=False, nullable=False)
    is_starred = Column(Boolean, default=False, nullable=False)
    forward_reason = Column(String(32), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="voicemails")
    transcription = relationship("Transcription", uselist=False, back_populates="voicemail", cascade="all, delete-orphan")

class Transcription(Base):
    __tablename__ = "transcriptions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    voicemail_id = Column(UUID(as_uuid=True), ForeignKey("voicemails.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    transcript_text = Column(Text, nullable=False)
    detected_language = Column(String(10), nullable=False)
    confidence_score = Column(Numeric(4, 3), nullable=True)
    model_name = Column(String(64), nullable=False)
    processing_time_ms = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    voicemail = relationship("Voicemail", back_populates="transcription")

