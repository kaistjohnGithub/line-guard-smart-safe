from pathlib import Path

from app.config import settings
from app.schemas import ImageAnalyzeRequest, LiveMonitorRequest, VLMResponse, VideoAnalyzeRequest


TASK_PROMPTS = {
    "general-safety": "Assess worker actions, hazards, PPE, and unsafe conditions.",
    "ppe-check": "Check visible PPE items and list missing protective equipment.",
    "sop-check": "Compare visible actions against station SOP checkpoints.",
    "near-miss": "Focus on unsafe interactions and near-miss indicators.",
}


def _resolve_path(user_path: str) -> str:
    path = Path(user_path)
    if path.is_absolute():
        return str(path)
    return str((settings.project_root / path).resolve())


def analyze_image(payload: ImageAnalyzeRequest) -> VLMResponse:
    resolved_path = _resolve_path(payload.image_path)
    prompt = payload.prompt or TASK_PROMPTS[payload.task]
    model = payload.model_name or settings.default_vlm_model

    return VLMResponse(
        mode="image",
        status="placeholder",
        model=model,
        summary="Image analysis skeleton is ready. Replace this placeholder with safety_inspector.run_inference().",
        raw_source=str(settings.vila_poc_root / "safety_inspector.py"),
        result={
            "image_path": resolved_path,
            "task": payload.task,
            "prompt": prompt,
            "next_action": "Import run_inference from safety_inspector.py and map its JSON output here.",
        },
    )


def analyze_video(payload: VideoAnalyzeRequest) -> VLMResponse:
    resolved_path = _resolve_path(payload.video_path)
    model = payload.model_name or settings.default_vlm_model

    return VLMResponse(
        mode="video",
        status="placeholder",
        model=model,
        summary="Video analysis skeleton is ready. Replace this placeholder with describe_video.py integration.",
        raw_source=str(settings.vila_poc_root / "describe_video.py"),
        result={
            "video_path": resolved_path,
            "interval_sec": payload.interval_sec,
            "max_frames": payload.max_frames,
            "prompt": payload.prompt or TASK_PROMPTS["general-safety"],
            "next_action": "Call extract_frames() and VLM description helpers, then normalize into timeline events.",
        },
    )


def start_live_monitor(payload: LiveMonitorRequest) -> VLMResponse:
    model = payload.model_name or settings.default_vlm_model

    return VLMResponse(
        mode="live-monitor",
        status="placeholder",
        model=model,
        summary="Live monitoring skeleton is ready. Replace this placeholder with live_demo.SafetyMonitor orchestration.",
        raw_source=str(settings.vila_poc_root / "live_demo.py"),
        result={
            "source": payload.source,
            "webcam_id": payload.webcam_id,
            "rtsp_url": payload.rtsp_url,
            "fps": payload.fps,
            "iterations": payload.iterations,
            "next_action": "Wrap SafetyMonitor with background execution and stream status updates back to the frontend.",
        },
    )
