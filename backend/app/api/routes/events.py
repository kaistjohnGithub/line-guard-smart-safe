"""
/api/events — Events + Alerts query endpoints.
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Event, Alert, FrameResult

router = APIRouter(prefix="/api/events", tags=["events"])


@router.get("")
def list_events(
    camera_id: str = None,
    severity: str = None,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    q = db.query(Event).order_by(Event.occurred_at.desc())
    if camera_id:
        q = q.filter(Event.camera_id == camera_id)
    if severity:
        q = q.filter(Event.severity == severity)
    events = q.limit(limit).all()

    return [
        {
            "id": e.id,
            "camera_id": e.camera_id,
            "event_type": e.event_type,
            "severity": e.severity,
            "description": e.description,
            "confidence": float(e.confidence or 0),
            "metadata": e.metadata,
            "occurred_at": e.occurred_at,
        }
        for e in events
    ]


@router.get("/alerts")
def list_alerts(
    camera_id: str = None,
    status: str = None,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    q = db.query(Alert).order_by(Alert.created_at.desc())
    if camera_id:
        q = q.filter(Alert.camera_id == camera_id)
    if status:
        q = q.filter(Alert.status == status)
    alerts = q.limit(limit).all()

    return [
        {
            "id": a.id,
            "event_id": a.event_id,
            "camera_id": a.camera_id,
            "title": a.title,
            "severity": a.severity,
            "status": a.status,
            "created_at": a.created_at,
        }
        for a in alerts
    ]


@router.get("/frames")
def list_frames(
    camera_id: str = None,
    job_id: int = None,
    safety_status: str = None,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    q = db.query(FrameResult).order_by(FrameResult.created_at.desc())
    if camera_id:
        q = q.filter(FrameResult.camera_id == camera_id)
    if job_id:
        q = q.filter(FrameResult.job_id == job_id)
    if safety_status:
        q = q.filter(FrameResult.safety_status == safety_status)
    frames = q.limit(limit).all()

    return [
        {
            "id": f.id,
            "job_id": f.job_id,
            "camera_id": f.camera_id,
            "frame_idx": f.frame_idx,
            "timestamp_str": f.timestamp_str,
            "timestamp_sec": float(f.timestamp_sec or 0),
            "description": f.description,
            "safety_status": f.safety_status,
            "frame_url": f"/media/{f.frame_path}" if f.frame_path else None,
            "latency_ms": f.latency_ms,
            "created_at": f.created_at,
        }
        for f in frames
    ]
