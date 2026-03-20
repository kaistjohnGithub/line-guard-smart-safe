"""
/api/analyze — Video analysis pipeline endpoints.

POST /api/analyze/video   → upload video, create job, run Qwen in background
GET  /api/analyze/{id}    → job status + progress
GET  /api/analyze         → list all jobs
"""
import shutil
import uuid
from pathlib import Path

from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import AnalysisJob, FrameResult
from app.config import settings

router = APIRouter(prefix="/api/analyze", tags=["analyze"])

MEDIA_ROOT = Path(settings.media_root)


@router.post("/video")
async def analyze_video(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    camera_id: str = Form(...),
    interval_sec: float = Form(3.0),
    db: Session = Depends(get_db),
):
    """Upload a video and start Qwen analysis in the background."""
    if not file.content_type or "video" not in file.content_type:
        raise HTTPException(status_code=415, detail="Only video files are supported")

    # Save video to media
    videos_dir = MEDIA_ROOT / "videos"
    videos_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid.uuid4().hex}.mp4"
    video_path = videos_dir / filename

    with video_path.open("wb") as f:
        shutil.copyfileobj(file.file, f)

    # Create job record
    job = AnalysisJob(
        camera_id=camera_id,
        video_path=str(video_path),
        status="pending",
        interval_sec=interval_sec,
    )
    db.add(job)
    db.commit()
    db.refresh(job)

    # Run Qwen analysis in background
    from app.services.qwen_runner import run_analysis
    from app.database import SessionLocal

    def run_in_new_session(job_id: int):
        with SessionLocal() as new_db:
            run_analysis(job_id, new_db)

    background_tasks.add_task(run_in_new_session, job.id)

    return {
        "job_id": job.id,
        "status": "pending",
        "video": f"/media/videos/{filename}",
        "camera_id": camera_id,
        "message": "Analysis started. Poll /api/analyze/{job_id} for progress.",
    }


@router.get("/{job_id}")
def get_job_status(job_id: int, db: Session = Depends(get_db)):
    """Get analysis job status and results."""
    job: AnalysisJob = db.get(AnalysisJob, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    frames = (
        db.query(FrameResult)
        .filter(FrameResult.job_id == job_id)
        .order_by(FrameResult.frame_idx)
        .all()
    )

    return {
        "job_id": job.id,
        "camera_id": job.camera_id,
        "status": job.status,
        "model": job.model,
        "total_frames": job.total_frames,
        "processed_frames": job.processed_frames,
        "progress_pct": round(job.processed_frames / max(job.total_frames, 1) * 100),
        "error": job.error_msg,
        "started_at": job.started_at,
        "finished_at": job.finished_at,
        "created_at": job.created_at,
        "frames": [
            {
                "frame_idx": f.frame_idx,
                "timestamp_str": f.timestamp_str,
                "timestamp_sec": float(f.timestamp_sec or 0),
                "description": f.description,
                "safety_status": f.safety_status,
                "frame_url": f"/media/{f.frame_path}" if f.frame_path else None,
                "latency_ms": f.latency_ms,
            }
            for f in frames
        ],
    }


@router.get("")
def list_jobs(camera_id: str = None, limit: int = 20, db: Session = Depends(get_db)):
    """List analysis jobs, optionally filtered by camera."""
    q = db.query(AnalysisJob).order_by(AnalysisJob.created_at.desc())
    if camera_id:
        q = q.filter(AnalysisJob.camera_id == camera_id)
    jobs = q.limit(limit).all()

    return [
        {
            "job_id": j.id,
            "camera_id": j.camera_id,
            "status": j.status,
            "total_frames": j.total_frames,
            "processed_frames": j.processed_frames,
            "created_at": j.created_at,
        }
        for j in jobs
    ]
