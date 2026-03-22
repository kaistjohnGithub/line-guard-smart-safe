import os
from fastapi import APIRouter

from app.schemas import ImageAnalyzeRequest, LiveMonitorRequest, VLMResponse, VideoAnalyzeRequest
from app.services.vlm_service import analyze_image, analyze_video, start_live_monitor

router = APIRouter(prefix="/api/vlm", tags=["vlm"])

QWEN_SERVICE_URL = os.getenv("QWEN_SERVICE_URL", "http://host.docker.internal:8001")


@router.get("/health")
def qwen_health():
    """Proxy Qwen service health check."""
    try:
        import requests as req
        r = req.get(f"{QWEN_SERVICE_URL}/health", timeout=5)
        return r.json()
    except Exception as exc:
        return {"status": "unavailable", "error": str(exc), "flash_attn": False, "gpu": None}


@router.post("/toggle-flash-attn")
def toggle_flash_attn(enable: int = 1):
    """Toggle Flash Attention by reloading the Qwen model (~30–60s)."""
    try:
        import requests as req
        r = req.post(f"{QWEN_SERVICE_URL}/reload-flash-attn", data={"enable": enable}, timeout=180)
        return r.json()
    except Exception as exc:
        return {"status": "error", "error": str(exc), "flash_attn": False}


@router.post("/analyze-image", response_model=VLMResponse)
def post_analyze_image(payload: ImageAnalyzeRequest) -> VLMResponse:
    return analyze_image(payload)


@router.post("/analyze-video", response_model=VLMResponse)
def post_analyze_video(payload: VideoAnalyzeRequest) -> VLMResponse:
    return analyze_video(payload)


@router.post("/live-monitor/start", response_model=VLMResponse)
def post_start_live_monitor(payload: LiveMonitorRequest) -> VLMResponse:
    return start_live_monitor(payload)
