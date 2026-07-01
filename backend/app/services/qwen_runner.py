"""
Qwen video analysis runner.
Sends frames one-by-one to local Qwen service — saves each result to DB immediately
so the frontend sees progress in real-time.
"""
import os
import uuid
import cv2
from datetime import datetime, timedelta
from pathlib import Path
from sqlalchemy.orm import Session

from app.models import AnalysisJob, FrameResult, Event, Alert, MediaFile

MEDIA_ROOT = Path(os.getenv("MEDIA_ROOT", "/app/media"))
QWEN_SERVICE_URL = os.getenv("QWEN_SERVICE_URL", "http://host.docker.internal:8001")
_SEV = {"DANGER": "critical", "WARNING": "high", "SAFE": "low", "PENDING": "medium"}


def _detect_status(text: str) -> str:
    upper = text.upper()
    if "DANGER" in upper:
        return "DANGER"
    if "WARNING" in upper:
        return "WARNING"
    return "SAFE"


def _qwen_available() -> bool:
    try:
        import requests
        r = requests.get(f"{QWEN_SERVICE_URL}/health", timeout=3)
        return r.ok
    except Exception:
        return False


def _describe_frame(frame_bgr) -> tuple:
    """Send single JPEG frame to Qwen service → (description, latency_ms)."""
    import requests
    ok, buf = cv2.imencode(".jpg", frame_bgr, [cv2.IMWRITE_JPEG_QUALITY, 85])
    if not ok:
        return ("Cannot encode frame", 0)
    resp = requests.post(
        f"{QWEN_SERVICE_URL}/describe-frame",
        files={"file": ("frame.jpg", buf.tobytes(), "image/jpeg")},
        timeout=120,
    )
    resp.raise_for_status()
    data = resp.json()
    return data["description"], data["latency_ms"]


def _extract_frames(video_path: str, interval_sec: float, max_frames: int = 60) -> list:
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open video: {video_path}")
    fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
    step = max(1, int(fps * interval_sec))
    frames, idx, extracted = [], 0, 0
    while cap.isOpened() and extracted < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
        if idx % step == 0:
            ts = idx / fps
            frames.append({
                "frame_idx": idx,
                "timestamp_sec": round(ts, 2),
                "timestamp_str": str(timedelta(seconds=int(ts))),
                "frame": frame.copy(),
            })
            extracted += 1
        idx += 1
    cap.release()
    return frames


def _save_frame(job: AnalysisJob, fd: dict, description: str,
                latency_ms: int, qwen_ok: bool, db: Session):
    """Save frame image + event + frame_result to DB immediately."""
    safety_status = _detect_status(description) if qwen_ok else "PENDING"
    severity = _SEV.get(safety_status, "medium")

    # Save frame image
    frames_dir = MEDIA_ROOT / "frames" / job.camera_id
    frames_dir.mkdir(parents=True, exist_ok=True)
    fname = f"{uuid.uuid4().hex[:8]}_f{fd['frame_idx']:04d}.jpg"
    cv2.imwrite(str(frames_dir / fname), fd["frame"])
    frame_path = f"frames/{job.camera_id}/{fname}"

    # Event
    event = Event(
        camera_id=job.camera_id,
        event_type=f"VLM_{safety_status}",
        severity=severity,
        description=description[:500],
        confidence=0.90 if qwen_ok else None,
        extra_data={
            "job_id": job.id,
            "frame_idx": fd["frame_idx"],
            "timestamp_str": fd["timestamp_str"],
            "safety_status": safety_status,
        },
    )
    db.add(event)
    db.flush()

    db.add(MediaFile(
        event_id=event.id, camera_id=job.camera_id,
        file_type="image", filename=fname,
        filepath=frame_path, mime_type="image/jpeg",
    ))

    if safety_status in ("WARNING", "DANGER") and qwen_ok:
        db.add(Alert(
            event_id=event.id, camera_id=job.camera_id,
            title=f"{safety_status}: {description[:80]}",
            severity=severity, status="open",
        ))

    db.add(FrameResult(
        job_id=job.id, camera_id=job.camera_id, event_id=event.id,
        frame_idx=fd["frame_idx"],
        timestamp_sec=fd["timestamp_sec"],
        timestamp_str=fd["timestamp_str"],
        description=description,
        safety_status=safety_status,
        frame_path=frame_path,
        latency_ms=latency_ms,
    ))
    db.commit()


def run_analysis(job_id: int, db: Session):
    job: AnalysisJob = db.get(AnalysisJob, job_id)
    if not job:
        return

    job.status = "running"
    job.started_at = datetime.utcnow()
    db.commit()

    try:
        qwen_ok = _qwen_available()
        frames = _extract_frames(job.video_path, float(job.interval_sec))
        job.total_frames = len(frames)
        db.commit()

        for fd in frames:
            if qwen_ok:
                description, latency_ms = _describe_frame(fd["frame"])
            else:
                description = f"[{fd['timestamp_str']}] — Start Qwen Service to get AI analysis"
                latency_ms = 0

            _save_frame(job, fd, description, latency_ms, qwen_ok, db)
            job.processed_frames += 1
            db.commit()

        job.status = "done" if qwen_ok else "done_no_ai"
        job.finished_at = datetime.utcnow()
        db.commit()

    except Exception as exc:
        job.status = "failed"
        job.error_msg = str(exc)
        job.finished_at = datetime.utcnow()
        db.commit()
        raise
