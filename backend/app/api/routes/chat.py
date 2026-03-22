from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Camera, Event, FrameResult
from app.api.routes.cameras import _format_camera
from app.api.routes.processes import get_rule_set, get_sop
from app.services.chat_service import run_camera_chat
from app.services.prompt_builder import build_camera_chat_system_prompt

router = APIRouter(prefix="/api/chat", tags=["chat"])


class ChatMessage(BaseModel):
    role: str
    content: str


class CameraChatRequest(BaseModel):
    cameraId: str
    message: str
    provider: str = "gemini"
    model: str | None = None
    history: list[ChatMessage] = []


def _msg_to_dict(msg: ChatMessage) -> dict[str, str]:
    if hasattr(msg, "model_dump"):
        return msg.model_dump()
    return msg.dict()


def _get_recent_context(db: Session, camera_id: str) -> list[dict[str, Any]]:
    events = (
        db.query(Event)
        .filter(Event.camera_id == camera_id)
        .order_by(Event.occurred_at.desc())
        .limit(8)
        .all()
    )
    frames = (
        db.query(FrameResult)
        .filter(FrameResult.camera_id == camera_id)
        .order_by(FrameResult.created_at.desc())
        .limit(8)
        .all()
    )

    normalized = []
    for event in events:
        normalized.append({
            "id": f"event-{event.id}",
            "event_type": event.event_type,
            "event_type_label": event.event_type_label,
            "severity": event.severity,
            "description": event.description,
            "occurred_at": event.occurred_at.isoformat() if event.occurred_at else None,
            "video_offset_seconds": float(event.video_offset_seconds) if event.video_offset_seconds is not None else None,
            "source": "event",
        })

    for frame in frames:
        normalized.append({
            "id": f"frame-{frame.id}",
            "event_type": "frame_result",
            "event_type_label": "Frame Analysis",
            "severity": frame.safety_status,
            "description": frame.description,
            "timestamp_sec": float(frame.timestamp_sec) if frame.timestamp_sec is not None else None,
            "occurred_at": frame.created_at.isoformat() if frame.created_at else None,
            "source": "frame",
        })

    normalized.sort(key=lambda item: item.get("occurred_at") or "", reverse=True)
    return normalized[:12]


@router.post("/camera")
def post_camera_chat(body: CameraChatRequest, db: Session = Depends(get_db)):
    camera_id = (body.cameraId or "").strip().upper()
    camera = db.get(Camera, camera_id)
    if not camera:
        raise HTTPException(status_code=404, detail="Camera not found")

    cam_payload = _format_camera(camera, db)

    sop_data = None
    if cam_payload.get("processId") and cam_payload.get("sopId"):
        try:
            sop_data = get_sop(cam_payload["processId"], cam_payload["sopId"], db)
        except HTTPException:
            sop_data = None

    rule_data = None
    if cam_payload.get("processId"):
        possible_rule_sets = get_rule_set if callable(get_rule_set) else None
        if possible_rule_sets:
            from app.models import SafetyRuleSet

            rule_set = (
                db.query(SafetyRuleSet)
                .filter(SafetyRuleSet.process_id == cam_payload["processId"], SafetyRuleSet.active == True)  # noqa: E712
                .order_by(SafetyRuleSet.id.asc())
                .first()
            )
            if rule_set:
                try:
                    rule_data = get_rule_set(cam_payload["processId"], rule_set.id, db)
                except HTTPException:
                    rule_data = None

    recent_events = _get_recent_context(db, camera_id)
    system_prompt = build_camera_chat_system_prompt(
        cam_payload,
        sop_data=sop_data,
        rule_data=rule_data,
        recent_events=recent_events,
    )

    result = run_camera_chat(
        provider=body.provider,
        system_prompt=system_prompt,
        message=body.message,
        model=body.model,
        history=[_msg_to_dict(msg) for msg in body.history],
    )

    return {
        **result,
        "cameraId": camera_id,
        "context_used": {
            "has_summary": bool(cam_payload.get("aiSummary")),
            "sop_attached": bool(sop_data),
            "rule_set_attached": bool(rule_data),
            "events_count": len(recent_events),
        },
    }
