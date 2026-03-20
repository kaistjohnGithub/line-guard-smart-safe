"""SQLAlchemy ORM models for Line Guard."""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, Numeric, Boolean, BigInteger, ForeignKey, TIMESTAMP
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.database import Base


class Camera(Base):
    __tablename__ = "cameras"
    id         = Column(String(20), primary_key=True)
    name       = Column(String(100), nullable=False)
    zone       = Column(String(100))
    location   = Column(String(200))
    status     = Column(String(20), default="online")
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class Event(Base):
    __tablename__ = "events"
    id          = Column(Integer, primary_key=True, autoincrement=True)
    camera_id   = Column(String(20), ForeignKey("cameras.id"))
    event_type  = Column(String(50), nullable=False)
    severity    = Column(String(20), default="medium")
    description = Column(Text)
    confidence  = Column(Numeric(5, 2))
    extra_data  = Column("metadata", JSONB)
    occurred_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class Alert(Base):
    __tablename__ = "alerts"
    id               = Column(Integer, primary_key=True, autoincrement=True)
    event_id         = Column(Integer, ForeignKey("events.id"))
    camera_id        = Column(String(20), ForeignKey("cameras.id"))
    title            = Column(String(200), nullable=False)
    severity         = Column(String(20), default="medium")
    status           = Column(String(20), default="open")
    acknowledged_at  = Column(TIMESTAMP(timezone=True))
    resolved_at      = Column(TIMESTAMP(timezone=True))
    created_at       = Column(TIMESTAMP(timezone=True), server_default=func.now())


class MediaFile(Base):
    __tablename__ = "media_files"
    id         = Column(Integer, primary_key=True, autoincrement=True)
    event_id   = Column(Integer, ForeignKey("events.id"))
    camera_id  = Column(String(20), ForeignKey("cameras.id"))
    file_type  = Column(String(10), nullable=False)
    filename   = Column(String(300), nullable=False)
    filepath   = Column(String(500), nullable=False)
    size_bytes = Column(BigInteger)
    mime_type  = Column(String(80))
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class AnalysisJob(Base):
    __tablename__ = "analysis_jobs"
    id               = Column(Integer, primary_key=True, autoincrement=True)
    camera_id        = Column(String(20), ForeignKey("cameras.id"))
    video_path       = Column(String(500), nullable=False)
    status           = Column(String(20), default="pending")
    model            = Column(String(100), default="Qwen/Qwen2.5-VL-3B-Instruct")
    interval_sec     = Column(Numeric(4, 1), default=3.0)
    total_frames     = Column(Integer, default=0)
    processed_frames = Column(Integer, default=0)
    error_msg        = Column(Text)
    started_at       = Column(TIMESTAMP(timezone=True))
    finished_at      = Column(TIMESTAMP(timezone=True))
    created_at       = Column(TIMESTAMP(timezone=True), server_default=func.now())


class FrameResult(Base):
    __tablename__ = "frame_results"
    id             = Column(Integer, primary_key=True, autoincrement=True)
    job_id         = Column(Integer, ForeignKey("analysis_jobs.id", ondelete="CASCADE"))
    camera_id      = Column(String(20), ForeignKey("cameras.id"))
    event_id       = Column(Integer, ForeignKey("events.id"))
    frame_idx      = Column(Integer, nullable=False)
    timestamp_sec  = Column(Numeric(8, 2))
    timestamp_str  = Column(String(20))
    description    = Column(Text)
    safety_status  = Column(String(20))
    frame_path     = Column(String(500))
    latency_ms     = Column(Integer)
    created_at     = Column(TIMESTAMP(timezone=True), server_default=func.now())
