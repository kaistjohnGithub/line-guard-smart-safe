import os
import shutil
import subprocess
import uuid
from contextlib import asynccontextmanager
from pathlib import Path

import cv2
from fastapi import FastAPI, File, UploadFile, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text

from app.database import engine
from app.api.routes.health import router as health_router
from app.api.routes.incidents import router as incidents_router
from app.api.routes.vlm import router as vlm_router
from app.api.routes.analyze import router as analyze_router
from app.api.routes.events import router as events_router
from app.api.routes.import_results import router as import_router
from app.api.routes.cameras import router as cameras_router
from app.api.routes.processes import router as processes_router
from app.api.routes.prompts import router as prompts_router
from app.config import settings

@asynccontextmanager
async def lifespan(_app: FastAPI):
    with engine.connect() as conn:
        conn.execute(text("ALTER TABLE prompts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ"))
        conn.execute(text("ALTER TABLE prompts ADD COLUMN IF NOT EXISTS last_test_output TEXT"))
        conn.execute(text("ALTER TABLE prompts ADD COLUMN IF NOT EXISTS last_test_json JSONB"))
        conn.commit()
    yield


app = FastAPI(title=settings.app_name, version=settings.app_version, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(incidents_router)
app.include_router(vlm_router)
app.include_router(analyze_router)
app.include_router(events_router)
app.include_router(import_router)
app.include_router(cameras_router)
app.include_router(processes_router)
app.include_router(prompts_router)

# ── Media static files ────────────────────────────────────────────────────────
MEDIA_ROOT = Path(settings.media_root)
MEDIA_ROOT.mkdir(parents=True, exist_ok=True)
(MEDIA_ROOT / "images").mkdir(exist_ok=True)
(MEDIA_ROOT / "videos").mkdir(exist_ok=True)

app.mount("/media", StaticFiles(directory=str(MEDIA_ROOT)), name="media")


# ── Media upload endpoint ─────────────────────────────────────────────────────
ALLOWED_TYPES = {
    "image/jpeg": ("images", ".jpg"),
    "image/png":  ("images", ".png"),
    "video/mp4":  ("videos", ".mp4"),
}


def _extract_video_thumbnail(video_path: Path) -> str | None:
    thumbs_dir = MEDIA_ROOT / "thumbnails"
    thumbs_dir.mkdir(parents=True, exist_ok=True)

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        return None

    try:
        fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
        duration = frame_count / fps if fps > 0 and frame_count > 0 else 0
        probe_times = [0.1, 0.25, 0.5, 1.0, duration * 0.33 if duration > 0 else 0]
        probe_times = [max(0.0, t) for t in probe_times]

        frame = None
        for t in probe_times:
            if frame_count > 0:
                cap.set(cv2.CAP_PROP_POS_MSEC, int(t * 1000))
            ok, img = cap.read()
            if not ok or img is None:
                continue
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            if float(gray.mean()) < 18:
                frame = img
                continue
            frame = img
            break

        if frame is None:
            return None

        thumb_name = f"{video_path.stem}_thumb.jpg"
        thumb_path = thumbs_dir / thumb_name
        cv2.imwrite(str(thumb_path), frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
        return f"/media/thumbnails/{thumb_name}"
    finally:
        cap.release()


def _transcode_video_for_web(video_path: Path) -> Path:
    ffmpeg_bin = shutil.which("ffmpeg")
    if not ffmpeg_bin:
        raise RuntimeError("ffmpeg is not installed on the backend")

    output_path = video_path.with_name(f"{video_path.stem}_web.mp4")
    cmd = [
        ffmpeg_bin,
        "-y",
        "-i", str(video_path),
        "-movflags", "+faststart",
        "-pix_fmt", "yuv420p",
        "-an",
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-crf", "23",
        str(output_path),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0 or not output_path.exists() or output_path.stat().st_size == 0:
        if output_path.exists():
            output_path.unlink(missing_ok=True)
        detail = (proc.stderr or proc.stdout or "ffmpeg failed").strip()
        raise RuntimeError(detail.splitlines()[-1] if detail else "ffmpeg failed")

    video_path.unlink(missing_ok=True)
    output_path.replace(video_path)
    return video_path


def _resolve_media_path(media_url: str) -> Path:
    if not media_url.startswith("/media/"):
        raise HTTPException(status_code=400, detail="Only /media files can be removed")
    rel_path = media_url.removeprefix("/media/").strip("/")
    target = (MEDIA_ROOT / rel_path).resolve()
    media_root_resolved = MEDIA_ROOT.resolve()
    if media_root_resolved not in target.parents and target != media_root_resolved:
        raise HTTPException(status_code=400, detail="Invalid media path")
    return target


@app.post("/api/media/upload")
async def upload_media(file: UploadFile = File(...)):
    content_type = file.content_type or ""
    if content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=415, detail=f"Unsupported media type: {content_type}")

    subdir, ext = ALLOWED_TYPES[content_type]
    filename = f"{uuid.uuid4().hex}{ext}"
    dest = MEDIA_ROOT / subdir / filename

    with dest.open("wb") as f:
        shutil.copyfileobj(file.file, f)

    if subdir == "videos":
        try:
            dest = _transcode_video_for_web(dest)
        except RuntimeError as exc:
            dest.unlink(missing_ok=True)
            raise HTTPException(status_code=422, detail=f"Uploaded video could not be converted for browser playback: {exc}")

    thumbnail_url = _extract_video_thumbnail(dest) if subdir == "videos" else None

    return {
        "url":      f"/media/{subdir}/{filename}",
        "filename": filename,
        "type":     subdir.rstrip("s"),   # "image" or "video"
        "size":     dest.stat().st_size,
        "thumbnail_url": thumbnail_url,
    }


@app.delete("/api/media")
async def delete_media_file(url: str = Query(..., description="Stored /media URL to remove")):
    target = _resolve_media_path(url)
    if not target.exists():
        return {"deleted": False, "reason": "missing"}

    target.unlink(missing_ok=True)
    if target.parent.name == "videos":
        thumb = MEDIA_ROOT / "thumbnails" / f"{target.stem}_thumb.jpg"
        thumb.unlink(missing_ok=True)
    return {"deleted": True}


@app.get("/")
def read_root() -> dict:
    return {
        "message": "Line Guard backend",
        "docs":    "/docs",
        "health":  "/health",
        "media":   "/media/",
        "upload":  "POST /api/media/upload",
    }
