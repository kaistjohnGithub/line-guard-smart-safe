"""
/api/prompts — Prompt Library CRUD endpoints.

GET    /api/prompts           → list all active prompts
POST   /api/prompts           → create new prompt
PUT    /api/prompts/{id}      → update prompt
DELETE /api/prompts/{id}      → soft delete
PATCH  /api/prompts/{id}/pin  → toggle pinned
"""
import os
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Prompt

router = APIRouter(prefix="/api/prompts", tags=["prompts"])


class PromptCreate(BaseModel):
    name: str
    type: str = "CUSTOM"
    type_color: str = "#64748b"
    content: str = ""


class PromptUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    type_color: Optional[str] = None
    content: Optional[str] = None
    is_pinned: Optional[bool] = None


def _fmt(p: Prompt) -> dict:
    return {
        "id": p.id, "code": p.code or f"P-{p.id:02d}",
        "name": p.name, "type": p.type, "type_color": p.type_color or "#1d6ef5",
        "content": p.content or "", "is_system": p.is_system, "is_pinned": p.is_pinned,
        "created_at": p.created_at.isoformat() if p.created_at else None,
        "updated_at": p.updated_at.isoformat() if p.updated_at else None,
        "last_test_output": p.last_test_output or None,
        "last_test_json": p.last_test_json or None,
    }


@router.get("")
def list_prompts(db: Session = Depends(get_db)):
    rows = db.query(Prompt).filter(Prompt.active == True).order_by(Prompt.id).all()
    return [_fmt(p) for p in rows]


@router.post("", status_code=201)
def create_prompt(body: PromptCreate, db: Session = Depends(get_db)):
    p = Prompt(name=body.name, type=body.type, type_color=body.type_color,
               content=body.content, is_system=False, active=True)
    db.add(p)
    db.commit()
    db.refresh(p)
    # auto-set code
    p.code = f"P-{p.id:02d}"
    db.commit()
    db.refresh(p)
    return _fmt(p)


@router.put("/{prompt_id}")
def update_prompt(prompt_id: int, body: PromptUpdate, db: Session = Depends(get_db)):
    p = db.get(Prompt, prompt_id)
    if not p or not p.active:
        raise HTTPException(status_code=404, detail="Prompt not found")
    for field in ("name", "type", "type_color", "content", "is_pinned"):
        val = getattr(body, field)
        if val is not None:
            setattr(p, field, val)
    p.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(p)
    return _fmt(p)


@router.delete("/{prompt_id}", status_code=204)
def delete_prompt(prompt_id: int, db: Session = Depends(get_db)):
    p = db.get(Prompt, prompt_id)
    if not p:
        raise HTTPException(status_code=404, detail="Prompt not found")
    if p.is_system:
        raise HTTPException(status_code=403, detail="Cannot delete system prompt")
    p.active = False
    db.commit()


@router.patch("/{prompt_id}/pin", status_code=200)
def toggle_pin(prompt_id: int, db: Session = Depends(get_db)):
    p = db.get(Prompt, prompt_id)
    if not p or not p.active:
        raise HTTPException(status_code=404, detail="Prompt not found")
    p.is_pinned = not p.is_pinned
    db.commit()
    return {"id": p.id, "is_pinned": p.is_pinned}


class SaveResultBody(BaseModel):
    output: Optional[str] = None
    result_json: Optional[dict] = None


@router.patch("/{prompt_id}/save-result")
def save_test_result(prompt_id: int, body: SaveResultBody, db: Session = Depends(get_db)):
    p = db.get(Prompt, prompt_id)
    if not p or not p.active:
        raise HTTPException(status_code=404, detail="Prompt not found")
    p.last_test_output = body.output
    p.last_test_json = body.result_json
    p.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(p)
    return _fmt(p)


QWEN_SERVICE_URL = os.getenv("QWEN_SERVICE_URL", "http://host.docker.internal:8001")


def _build_prompt(base_prompt: str, sop_context: str, mode: str = "image") -> str:
    if not sop_context or not sop_context.strip():
        return base_prompt
    compare_note = (
        "Compare what you observe in the image against the SOP above. "
        if mode == "image" else
        "Compare what you observe in these frames against the SOP above. "
    )
    return (
        "=== REFERENCE SOP (USE AS GROUND TRUTH) ===\n"
        + sop_context.strip()
        + "\n\nIMPORTANT: The SOP above describes exactly what workers SHOULD be doing and what tools/PPE they use. "
        "Use it as authoritative reference. Do NOT invent tools or actions not mentioned in the SOP unless clearly visible. "
        "When the SOP says a worker uses their eyes for inspection — accept that, do not assume magnifying glass or other tools.\n\n"
        "=== ANALYSIS TASK ===\n"
        + base_prompt
        + "\n\n" + compare_note
        + "Highlight any DEVIATIONS from the SOP procedure, missing PPE, or unsafe conditions relative to the defined safety rules."
    )


@router.post("/{prompt_id}/test")
async def test_prompt(
    prompt_id: int,
    file: UploadFile = File(...),
    sop_context: str = Form(""),
    max_new_tokens: int = Form(300),
    resolution: int = Form(480),
    db: Session = Depends(get_db),
):
    """Send an uploaded image to the Qwen service using this prompt's content + optional SOP context."""
    p = db.get(Prompt, prompt_id)
    if not p or not p.active:
        raise HTTPException(status_code=404, detail="Prompt not found")

    image_bytes = await file.read()
    full_prompt = _build_prompt((p.content or "").strip(), sop_context, "image")

    try:
        import requests as req
        resp = req.post(
            f"{QWEN_SERVICE_URL}/describe-frame",
            files={"file": (file.filename or "frame.jpg", image_bytes, file.content_type or "image/jpeg")},
            data={"prompt": full_prompt, "max_new_tokens": str(max_new_tokens), "resolution": str(resolution)},
            timeout=120,
        )
        resp.raise_for_status()
        data = resp.json()
        return {
            "status": "ok",
            "description": data.get("description", ""),
            "latency_ms": data.get("latency_ms", 0),
            "prompt_name": p.name,
            "vlm_input": {
                "prompt_base": (p.content or "").strip(),
                "sop_context": sop_context.strip() or None,
                "full_prompt_sent": full_prompt,
                "settings": {
                    "max_new_tokens": max_new_tokens,
                    "resolution": resolution,
                    "file": file.filename,
                },
            },
        }
    except Exception as exc:
        return {"status": "unavailable",
                "description": f"Qwen service not reachable ({QWEN_SERVICE_URL}). Start the GPU worker to enable live inference.\n\nError: {exc}",
                "latency_ms": 0, "prompt_name": p.name}


@router.post("/{prompt_id}/test-video")
async def test_prompt_video(
    prompt_id: int,
    file: UploadFile = File(...),
    sop_context: str = Form(""),
    interval_sec: float = Form(3.0),
    max_frames: int = Form(5),
    max_new_tokens: int = Form(300),
    resolution: int = Form(480),
    multi_frame: int = Form(1),
    db: Session = Depends(get_db),
):
    """Send an uploaded video to the Qwen service — extract frames at interval, run VLM on each."""
    p = db.get(Prompt, prompt_id)
    if not p or not p.active:
        raise HTTPException(status_code=404, detail="Prompt not found")

    video_bytes = await file.read()

    base_prompt = (p.content or "").strip()
    full_prompt = _build_prompt((p.content or "").strip(), sop_context, "video")

    try:
        import requests as req
        import time as _time
        t0 = _time.time()
        resp = req.post(
            f"{QWEN_SERVICE_URL}/analyze",
            files={"file": (file.filename or "video.mp4", video_bytes, file.content_type or "video/mp4")},
            data={
                "prompt": full_prompt,
                "interval_sec": str(interval_sec),
                "max_frames": str(max_frames),
                "max_new_tokens": str(max_new_tokens),
                "resolution": str(resolution),
                "multi_frame": str(multi_frame),
            },
            timeout=600,
        )
        resp.raise_for_status()
        data = resp.json()
        total_ms = int((_time.time() - t0) * 1000)
        return {
            "status": "ok",
            "total_frames": data.get("total_frames", 0),
            "frames": data.get("frames", []),
            "latency_ms": total_ms,
            "prompt_name": p.name,
            "vlm_input": {
                "prompt_base": base_prompt,
                "sop_context": sop_context.strip() or None,
                "full_prompt_sent": full_prompt,
                "settings": {
                    "max_new_tokens": max_new_tokens,
                    "resolution": resolution,
                    "interval_sec": interval_sec,
                    "max_frames": max_frames,
                    "multi_frame": multi_frame,
                    "file": file.filename,
                },
            },
        }
    except Exception as exc:
        return {
            "status": "unavailable",
            "frames": [],
            "total_frames": 0,
            "description": f"Qwen service not reachable ({QWEN_SERVICE_URL}).\n\nError: {exc}",
            "latency_ms": 0,
            "prompt_name": p.name,
        }
