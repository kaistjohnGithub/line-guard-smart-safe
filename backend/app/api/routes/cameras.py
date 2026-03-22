"""
/api/cameras - camera fleet endpoints for the monitoring UI.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Alert, AnalysisJob, Camera, Event, FrameResult, MediaFile, Process, Sop

router = APIRouter(prefix="/api/cameras", tags=["cameras"])


class CameraBase(BaseModel):
    name: str
    processId: int | None = None
    sopId: int | None = None
    process: str | None = None
    station: str | None = None
    fps: int = 15
    videoSrc: str | None = None
    status: str = "online"
    zone: str | None = None
    location: str | None = None


class CameraCreate(CameraBase):
    id: str | None = None


class CameraUpdate(CameraBase):
    pass


def _normalize_status(status: str | None) -> str:
    status_map = {
        "online": "online",
        "offline": "offline",
        "warning": "delay",
        "delay": "delay",
        "critical": "critical",
    }
    return status_map.get((status or "").lower(), "online")


def _to_risk_label(severity: str | None, camera_status: str) -> str:
    sev = (severity or "").lower()
    if camera_status == "offline":
        return "N/A"
    if sev == "critical":
        return "CRITICAL"
    if sev == "high":
        return "HIGH"
    if sev == "medium":
        return "MED"
    if sev == "low":
        return "LOW"
    return "LOW" if camera_status == "online" else "MED"


def _next_camera_id(cameras: list[Camera]) -> str:
    best_letter = "A"
    best_num = 0
    for cam in cameras:
      cid = (cam.id or "").upper()
      if not cid.startswith("CAM-") or len(cid) < 7:
          continue
      suffix = cid[4:]
      letter = suffix[:1]
      digits = suffix[1:]
      if not (letter.isalpha() and digits.isdigit()):
          continue
      num = int(digits)
      if letter > best_letter or (letter == best_letter and num > best_num):
          best_letter = letter
          best_num = num

    next_letter = best_letter
    next_num = best_num + 1
    if next_num > 99:
        next_letter = chr(ord(best_letter) + 1)
        next_num = 1
    return f"CAM-{next_letter}{next_num:02d}"


def _thumbnail_url_from_video(video_src: str | None) -> str | None:
    if not video_src or not video_src.startswith("/media/videos/"):
        return None
    filename = video_src.rsplit("/", 1)[-1]
    if "." not in filename:
        return None
    stem = filename.rsplit(".", 1)[0]
    return f"/media/thumbnails/{stem}_thumb.jpg"


def _camera_has_related_records(db: Session, camera_id: str) -> bool:
    return bool(
        db.query(Event).filter(Event.camera_id == camera_id).first()
        or db.query(Alert).filter(Alert.camera_id == camera_id).first()
        or db.query(AnalysisJob).filter(AnalysisJob.camera_id == camera_id).first()
        or db.query(FrameResult).filter(FrameResult.camera_id == camera_id).first()
        or db.query(MediaFile).filter(MediaFile.camera_id == camera_id).first()
    )


def _format_camera(cam: Camera, db: Session) -> dict:
    normalized_status = _normalize_status(cam.status)
    proc = db.get(Process, cam.process_id) if getattr(cam, "process_id", None) else None
    sop = db.get(Sop, cam.sop_id) if getattr(cam, "sop_id", None) else None
    process_name = proc.name if proc else (cam.process or cam.zone or "Unassigned")

    open_alerts = (
        db.query(Alert)
        .filter(Alert.camera_id == cam.id, Alert.status == "open")
        .order_by(Alert.created_at.desc())
        .all()
    )
    latest_event = (
        db.query(Event)
        .filter(Event.camera_id == cam.id)
        .order_by(Event.occurred_at.desc())
        .first()
    )

    highest_open_alert = next(
        (sev for sev in ("critical", "high", "medium", "low")
         if any((a.severity or "").lower() == sev for a in open_alerts)),
        None,
    )
    risk_source = highest_open_alert or (latest_event.severity if latest_event else None)

    return {
        "id": cam.id,
        "name": cam.name,
        "processId": cam.process_id,
        "sopId": cam.sop_id,
        "sopTitle": sop.title if sop else None,
        "process": process_name,
        "station": cam.station or cam.location or cam.name,
        "status": normalized_status,
        "fps": cam.fps if cam.fps is not None else (15 if normalized_status == "online" else 3 if normalized_status == "delay" else 0),
        "alerts": len(open_alerts),
        "risk": _to_risk_label(risk_source, normalized_status),
        "videoSrc": cam.video_src,
        "thumbnailUrl": _thumbnail_url_from_video(cam.video_src),
        "location": cam.location,
        "zone": cam.zone,
        "archived": bool(getattr(cam, "archived", False)),
        "archivedAt": getattr(cam, "archived_at", None),
        "hasHistory": _camera_has_related_records(db, cam.id),
        "last_event_at": latest_event.occurred_at if latest_event else None,
    }


@router.get("")
def list_cameras(include_archived: bool = False, db: Session = Depends(get_db)):
    query = db.query(Camera)
    if not include_archived:
        query = query.filter((Camera.archived == False) | (Camera.archived.is_(None)))  # noqa: E712
    cameras = query.order_by(Camera.id).all()
    return [_format_camera(cam, db) for cam in cameras]


@router.get("/next-id")
def get_next_camera_id(db: Session = Depends(get_db)):
    cameras = db.query(Camera).order_by(Camera.id).all()
    return {"id": _next_camera_id(cameras)}


@router.post("", status_code=201)
def create_camera(body: CameraCreate, db: Session = Depends(get_db)):
    all_cameras = db.query(Camera).order_by(Camera.id).all()
    camera_id = (body.id or "").strip().upper() or _next_camera_id(all_cameras)
    name = (body.name or "").strip()
    status = _normalize_status(body.status)
    process = db.get(Process, body.processId) if body.processId else None
    sop = db.get(Sop, body.sopId) if body.sopId else None

    if not camera_id or not name:
        raise HTTPException(status_code=400, detail="Camera ID and name are required")
    if not body.processId:
        raise HTTPException(status_code=400, detail="Process is required")
    if db.get(Camera, camera_id):
        raise HTTPException(status_code=409, detail=f"Camera '{camera_id}' already exists")
    if body.processId and not process:
        raise HTTPException(status_code=404, detail="Selected process not found")
    if body.sopId and not sop:
        raise HTTPException(status_code=404, detail="Selected SOP not found")
    if body.sopId and sop and sop.process_id != body.processId:
        raise HTTPException(status_code=400, detail="Selected SOP does not belong to the selected process")

    db_camera = Camera(
        id=camera_id,
        name=name,
        process_id=body.processId,
        sop_id=body.sopId,
        process=(process.name if process else (body.process or "").strip()) or (body.zone or "").strip() or None,
        station=(body.station or "").strip() or (body.location or "").strip() or None,
        fps=max(0, int(body.fps or 0)),
        video_src=(body.videoSrc or "").strip() or None,
        zone=(body.zone or "").strip() or None,
        location=(body.location or "").strip() or None,
        status="warning" if status == "delay" else status,
    )
    db.add(db_camera)
    db.commit()
    db.refresh(db_camera)
    return _format_camera(db_camera, db)


@router.put("/{camera_id}")
def update_camera(camera_id: str, body: CameraUpdate, db: Session = Depends(get_db)):
    cam = db.get(Camera, camera_id.upper())
    if not cam:
        raise HTTPException(status_code=404, detail="Camera not found")

    status = _normalize_status(body.status)
    process = db.get(Process, body.processId) if body.processId else None
    sop = db.get(Sop, body.sopId) if body.sopId else None
    if not body.processId:
        raise HTTPException(status_code=400, detail="Process is required")
    if body.processId and not process:
        raise HTTPException(status_code=404, detail="Selected process not found")
    if body.sopId and not sop:
        raise HTTPException(status_code=404, detail="Selected SOP not found")
    if body.sopId and sop and sop.process_id != body.processId:
        raise HTTPException(status_code=400, detail="Selected SOP does not belong to the selected process")

    cam.name = (body.name or "").strip() or cam.name
    cam.process_id = body.processId
    cam.sop_id = body.sopId
    cam.process = (process.name if process else (body.process or "").strip()) or (body.zone or "").strip() or None
    cam.station = (body.station or "").strip() or (body.location or "").strip() or None
    cam.fps = max(0, int(body.fps or 0))
    cam.video_src = (body.videoSrc or "").strip() or None
    cam.zone = (body.zone or "").strip() or None
    cam.location = (body.location or "").strip() or None
    cam.status = "warning" if status == "delay" else status
    db.commit()
    db.refresh(cam)
    return _format_camera(cam, db)


@router.patch("/{camera_id}/video")
def update_camera_video(camera_id: str, body: dict, db: Session = Depends(get_db)):
    cam = db.get(Camera, camera_id.upper())
    if not cam:
        raise HTTPException(status_code=404, detail="Camera not found")
    cam.video_src = (body.get("videoSrc") or "").strip() or None
    db.commit()
    db.refresh(cam)
    return _format_camera(cam, db)


@router.delete("/{camera_id}", status_code=204)
def delete_camera(camera_id: str, db: Session = Depends(get_db)):
    cam = db.get(Camera, camera_id.upper())
    if not cam:
        raise HTTPException(status_code=404, detail="Camera not found")

    if _camera_has_related_records(db, cam.id):
        raise HTTPException(status_code=409, detail="Cannot delete camera because it has related alerts, events, or analysis history. Archive it instead.")

    db.delete(cam)
    db.commit()
    return Response(status_code=204)


@router.post("/{camera_id}/archive")
def archive_camera(camera_id: str, db: Session = Depends(get_db)):
    cam = db.get(Camera, camera_id.upper())
    if not cam:
        raise HTTPException(status_code=404, detail="Camera not found")
    if getattr(cam, "archived", False):
        return _format_camera(cam, db)

    cam.archived = True
    cam.archived_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(cam)
    return _format_camera(cam, db)


@router.post("/{camera_id}/restore")
def restore_camera(camera_id: str, db: Session = Depends(get_db)):
    cam = db.get(Camera, camera_id.upper())
    if not cam:
        raise HTTPException(status_code=404, detail="Camera not found")

    cam.archived = False
    cam.archived_at = None
    db.commit()
    db.refresh(cam)
    return _format_camera(cam, db)
