"""
POST /api/analyze/import — Import Qwen JSON results into DB.

Accepts the output format from describe_video_qwen.py:
{
  "video": "...", "model": "...", "frames": [
    {"timestamp_str": "0:00:00", "timestamp_sec": 0, "frame_idx": 0,
     "description": "...", "latency_ms": 1234}
  ]
}
"""
from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import AnalysisJob, FrameResult, Event, Alert

router = APIRouter(prefix="/api/analyze/import", tags=["analyze"])

_SEV = {"DANGER": "critical", "WARNING": "high", "SAFE": "low", "PENDING": "medium"}


def _detect_status(text: str) -> str:
    upper = text.upper()
    if "DANGER" in upper:
        return "DANGER"
    if "WARNING" in upper:
        return "WARNING"
    return "SAFE"


class FrameIn(BaseModel):
    timestamp_str: str = ""
    timestamp_sec: float = 0.0
    frame_idx: int = 0
    description: str = ""
    latency_ms: int = 0
    frame_path: str | None = None   # optional saved frame path


class ImportPayload(BaseModel):
    camera_id: str
    video: str = ""
    model: str = "Qwen/Qwen2.5-VL-3B-Instruct"
    interval_sec: float = 3.0
    frames: list[FrameIn]


@router.post("")
def import_results(payload: ImportPayload, db: Session = Depends(get_db)):
    """Import pre-computed Qwen analysis JSON into the database."""
    if not payload.frames:
        raise HTTPException(status_code=400, detail="No frames provided")

    # Create analysis job record
    job = AnalysisJob(
        camera_id=payload.camera_id,
        video_path=payload.video,
        status="done",
        model=payload.model,
        interval_sec=payload.interval_sec,
        total_frames=len(payload.frames),
        processed_frames=len(payload.frames),
        started_at=datetime.utcnow(),
        finished_at=datetime.utcnow(),
    )
    db.add(job)
    db.flush()

    danger_count = warning_count = safe_count = 0

    for f in payload.frames:
        safety_status = _detect_status(f.description)
        severity = _SEV.get(safety_status, "medium")

        if safety_status == "DANGER":
            danger_count += 1
        elif safety_status == "WARNING":
            warning_count += 1
        else:
            safe_count += 1

        # Create event
        event = Event(
            camera_id=payload.camera_id,
            event_type=f"VLM_{safety_status}",
            severity=severity,
            description=f.description[:500],
            confidence=0.90,
            extra_data={
                "job_id": job.id,
                "frame_idx": f.frame_idx,
                "timestamp_str": f.timestamp_str,
                "safety_status": safety_status,
                "latency_ms": f.latency_ms,
            },
        )
        db.add(event)
        db.flush()

        # Create alert for WARNING / DANGER
        if safety_status in ("WARNING", "DANGER"):
            db.add(Alert(
                event_id=event.id,
                camera_id=payload.camera_id,
                title=f"{safety_status}: {f.description[:80]}",
                severity=severity,
                status="open",
            ))

        # Save frame result
        db.add(FrameResult(
            job_id=job.id,
            camera_id=payload.camera_id,
            event_id=event.id,
            frame_idx=f.frame_idx,
            timestamp_sec=f.timestamp_sec,
            timestamp_str=f.timestamp_str,
            description=f.description,
            safety_status=safety_status,
            frame_path=f.frame_path,
            latency_ms=f.latency_ms,
        ))

    db.commit()

    return {
        "job_id": job.id,
        "camera_id": payload.camera_id,
        "total_frames": len(payload.frames),
        "summary": {
            "DANGER": danger_count,
            "WARNING": warning_count,
            "SAFE": safe_count,
        },
        "message": f"Imported {len(payload.frames)} frames successfully.",
    }
