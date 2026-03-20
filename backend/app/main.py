import os
import shutil
import uuid
from pathlib import Path

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.routes.health import router as health_router
from app.api.routes.incidents import router as incidents_router
from app.api.routes.vlm import router as vlm_router
from app.config import settings

app = FastAPI(title=settings.app_name, version=settings.app_version)

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

    return {
        "url":      f"/media/{subdir}/{filename}",
        "filename": filename,
        "type":     subdir.rstrip("s"),   # "image" or "video"
        "size":     dest.stat().st_size,
    }


@app.get("/")
def read_root() -> dict:
    return {
        "message": "Line Guard backend",
        "docs":    "/docs",
        "health":  "/health",
        "media":   "/media/",
        "upload":  "POST /api/media/upload",
    }
