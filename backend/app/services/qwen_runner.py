"""
Qwen2.5-VL video analysis runner.
Called as a FastAPI BackgroundTask — saves results directly to PostgreSQL.
"""
import os
import re
import time
import uuid
from datetime import datetime, timedelta
from pathlib import Path

import cv2
from sqlalchemy.orm import Session

from app.models import AnalysisJob, FrameResult, Event, Alert, MediaFile

MEDIA_ROOT = Path(os.getenv("MEDIA_ROOT", "/app/media"))

DEFAULT_PROMPT = (
    "You are a factory safety inspector. Describe this scene in detail:\n"
    "1. Workers visible and their PPE (helmet, vest, gloves, boots)\n"
    "2. Equipment and machinery (forklifts, conveyors, etc.)\n"
    "3. Safety hazards or violations\n"
    "4. Overall safety status: SAFE / WARNING / DANGER"
)

# Severity mapping
_SEV = {"DANGER": "critical", "WARNING": "high", "SAFE": "low"}


def _detect_status(text: str) -> str:
    upper = text.upper()
    if "DANGER" in upper:
        return "DANGER"
    if "WARNING" in upper:
        return "WARNING"
    return "SAFE"


def _extract_frames(video_path: str, interval_sec: float, max_frames: int = 60) -> list:
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open video: {video_path}")

    fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
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


def _save_frame_image(frame_bgr, camera_id: str, frame_idx: int) -> str:
    """Save frame as JPEG, return relative path."""
    frames_dir = MEDIA_ROOT / "frames" / camera_id
    frames_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid.uuid4().hex[:8]}_f{frame_idx:04d}.jpg"
    path = frames_dir / filename
    cv2.imwrite(str(path), frame_bgr)
    return f"frames/{camera_id}/{filename}"


def run_analysis(job_id: int, db: Session):
    """Main analysis function — runs in background."""
    job: AnalysisJob = db.get(AnalysisJob, job_id)
    if not job:
        return

    job.status = "running"
    job.started_at = datetime.utcnow()
    db.commit()

    try:
        # Load Qwen model
        from app.services.qwen_model import describe_frame, load_model
        load_model()

        frames = _extract_frames(job.video_path, float(job.interval_sec))
        job.total_frames = len(frames)
        db.commit()

        for fd in frames:
            t0 = time.time()
            description = describe_frame(fd["frame"])
            latency_ms = int((time.time() - t0) * 1000)

            safety_status = _detect_status(description)
            frame_path = _save_frame_image(fd["frame"], job.camera_id, fd["frame_idx"])

            # Create Event
            event_type = f"VLM_{safety_status}"
            severity = _SEV.get(safety_status, "medium")
            event = Event(
                camera_id=job.camera_id,
                event_type=event_type,
                severity=severity,
                description=description[:500],
                confidence=0.85,
                extra_data={
                    "job_id": job_id,
                    "frame_idx": fd["frame_idx"],
                    "timestamp_str": fd["timestamp_str"],
                    "safety_status": safety_status,
                },
            )
            db.add(event)
            db.flush()

            # Save frame image record
            db.add(MediaFile(
                event_id=event.id,
                camera_id=job.camera_id,
                file_type="image",
                filename=Path(frame_path).name,
                filepath=frame_path,
                mime_type="image/jpeg",
            ))

            # Create Alert for WARNING / DANGER
            if safety_status in ("WARNING", "DANGER"):
                db.add(Alert(
                    event_id=event.id,
                    camera_id=job.camera_id,
                    title=f"{safety_status}: {description[:80]}",
                    severity=severity,
                    status="open",
                ))

            # Save FrameResult
            db.add(FrameResult(
                job_id=job_id,
                camera_id=job.camera_id,
                event_id=event.id,
                frame_idx=fd["frame_idx"],
                timestamp_sec=fd["timestamp_sec"],
                timestamp_str=fd["timestamp_str"],
                description=description,
                safety_status=safety_status,
                frame_path=frame_path,
                latency_ms=latency_ms,
            ))

            job.processed_frames += 1
            db.commit()

        job.status = "done"
        job.finished_at = datetime.utcnow()
        db.commit()

    except Exception as exc:
        job.status = "failed"
        job.error_msg = str(exc)
        job.finished_at = datetime.utcnow()
        db.commit()
        raise
