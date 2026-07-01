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
    process_id = Column(Integer)
    sop_id     = Column(Integer)
    process    = Column(String(150))
    station    = Column(String(150))
    fps        = Column(Integer, default=15)
    video_src  = Column(String(500))
    zone       = Column(String(100))
    location   = Column(String(200))
    status     = Column(String(20), default="online")
    archived   = Column(Boolean, default=False)
    archived_at = Column(TIMESTAMP(timezone=True))
    ai_summary = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class Event(Base):
    __tablename__ = "events"
    id                   = Column(Integer, primary_key=True, autoincrement=True)
    camera_id            = Column(String(20), ForeignKey("cameras.id"))
    event_type           = Column(String(50), nullable=False)
    event_type_label     = Column(Text)
    severity             = Column(String(20), default="medium")
    description          = Column(Text)
    confidence           = Column(Numeric(5, 2))
    extra_data           = Column("metadata", JSONB)
    occurred_at          = Column(TIMESTAMP(timezone=True), server_default=func.now())
    video_offset_seconds = Column(Numeric(8, 2))


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


class Process(Base):
    __tablename__ = "processes"
    id          = Column(Integer, primary_key=True, autoincrement=True)
    code        = Column(String(30), nullable=False, unique=True)
    name        = Column(String(200), nullable=False)
    name_th     = Column(String(200))
    description = Column(Text)
    active      = Column(Boolean, default=True)
    created_at  = Column(TIMESTAMP(timezone=True), server_default=func.now())


class Sop(Base):
    __tablename__ = "sops"
    id          = Column(Integer, primary_key=True, autoincrement=True)
    process_id  = Column(Integer, ForeignKey("processes.id"))
    code        = Column(String(30), nullable=False, unique=True)
    title       = Column(String(200), nullable=False)
    title_th    = Column(String(200))
    version     = Column(String(10), default="1.0")
    purpose     = Column(Text)
    responsible = Column(Text)
    equipment   = Column(Text)
    kpi         = Column(Text)
    safety_rules = Column(Text)
    status      = Column(String(20), default='draft')
    active      = Column(Boolean, default=True)
    created_at  = Column(TIMESTAMP(timezone=True), server_default=func.now())


class SopStep(Base):
    __tablename__ = "sop_steps"
    id          = Column(Integer, primary_key=True, autoincrement=True)
    sop_id      = Column(Integer, ForeignKey("sops.id", ondelete="CASCADE"))
    step_no     = Column(Integer, nullable=False)
    title       = Column(String(200))
    title_th    = Column(String(200))
    description = Column(Text)
    is_critical = Column(Boolean, default=False)


class SafetyRuleSet(Base):
    __tablename__ = "safety_rule_sets"
    id          = Column(Integer, primary_key=True, autoincrement=True)
    process_id  = Column(Integer, ForeignKey("processes.id"))
    title       = Column(String(200), nullable=False)
    title_th    = Column(String(200))
    version     = Column(String(10), default="1.0")
    active      = Column(Boolean, default=True)
    created_at  = Column(TIMESTAMP(timezone=True), server_default=func.now())


class SafetyRuleItem(Base):
    __tablename__ = "safety_rule_items"
    id           = Column(Integer, primary_key=True, autoincrement=True)
    rule_set_id  = Column(Integer, ForeignKey("safety_rule_sets.id", ondelete="CASCADE"))
    category     = Column(String(50), nullable=False)
    rule_text    = Column(Text, nullable=False)
    rule_text_th = Column(Text)
    severity     = Column(String(20), default="medium")
    is_prohibited = Column(Boolean, default=False)
    sort_order   = Column(Integer, default=0)
    sub_section  = Column(String(50))


class Prompt(Base):
    __tablename__ = "prompts"
    id               = Column(Integer, primary_key=True, autoincrement=True)
    code             = Column(String(20), unique=True)
    name             = Column(String(200), nullable=False)
    type             = Column(String(50), default="CUSTOM")
    type_color       = Column(String(20), default="#1d6ef5")
    content          = Column(Text, nullable=False, default="")
    is_system        = Column(Boolean, default=False)
    is_pinned        = Column(Boolean, default=False)
    active           = Column(Boolean, default=True)
    created_at       = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at       = Column(TIMESTAMP(timezone=True))
    last_test_output = Column(Text)
    last_test_json   = Column(JSONB)


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
    process_id       = Column(Integer, ForeignKey("processes.id"))
    sop_id           = Column(Integer, ForeignKey("sops.id"))
    rule_set_id      = Column(Integer, ForeignKey("safety_rule_sets.id"))
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
