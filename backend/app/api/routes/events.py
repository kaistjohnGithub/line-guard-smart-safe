"""
/api/events — Events + Alerts query endpoints.
"""
from datetime import timezone as _tz
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Camera, Event, Alert, FrameResult

router = APIRouter(prefix="/api/events", tags=["events"])


class EventIn(BaseModel):
    timestamp_mmss: str            # "01:13"
    severity: str = "medium"      # low / medium / high / critical
    description: str = ""
    event_type: str = "observation"
    event_type_label: Optional[str] = None


class BulkEventBody(BaseModel):
    camera_id: str
    events: List[EventIn]
    replace: bool = False          # ถ้า True ลบ events เดิมของกล้องนี้ก่อน


def _mmss_to_sec(mmss: str) -> float:
    """'01:13' → 73.0, '2:55' → 175.0"""
    parts = mmss.strip().split(":")
    try:
        if len(parts) == 2:
            return int(parts[0]) * 60 + float(parts[1])
        return float(parts[0])
    except ValueError:
        return 0.0


@router.get("")
def list_events(
    camera_id: str = None,
    severity: str = None,
    limit: int = 500,
    db: Session = Depends(get_db),
):
    q = db.query(Event).order_by(Event.video_offset_seconds.asc().nullslast(), Event.occurred_at.asc())
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
            "event_type_label": e.event_type_label,
            "severity": e.severity,
            "description": e.description,
            "confidence": float(e.confidence or 0),
            "occurred_at": e.occurred_at,
            "video_offset_seconds": float(e.video_offset_seconds) if e.video_offset_seconds is not None else None,
        }
        for e in events
    ]


@router.post("/bulk", status_code=201)
def bulk_create_events(body: BulkEventBody, db: Session = Depends(get_db)):
    cam = db.get(Camera, body.camera_id.upper())
    if not cam:
        raise HTTPException(status_code=404, detail=f"Camera '{body.camera_id}' not found")

    if body.replace:
        db.query(Event).filter(
            Event.camera_id == cam.id,
            Event.video_offset_seconds.isnot(None),
        ).delete(synchronize_session=False)

    created = []
    for ev in body.events:
        offset = _mmss_to_sec(ev.timestamp_mmss)
        sev = ev.severity.lower()
        row = Event(
            camera_id=cam.id,
            event_type=ev.event_type,
            event_type_label=ev.event_type_label,
            severity=sev,
            description=ev.description,
            video_offset_seconds=offset,
        )
        db.add(row)
        created.append(row)

    db.commit()
    for r in created:
        db.refresh(r)

    return {"created": len(created), "camera_id": cam.id}


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
