from fastapi import APIRouter

from app.schemas import ImageAnalyzeRequest, LiveMonitorRequest, VLMResponse, VideoAnalyzeRequest
from app.services.vlm_service import analyze_image, analyze_video, start_live_monitor

router = APIRouter(prefix="/api/vlm", tags=["vlm"])


@router.post("/analyze-image", response_model=VLMResponse)
def post_analyze_image(payload: ImageAnalyzeRequest) -> VLMResponse:
    return analyze_image(payload)


@router.post("/analyze-video", response_model=VLMResponse)
def post_analyze_video(payload: VideoAnalyzeRequest) -> VLMResponse:
    return analyze_video(payload)


@router.post("/live-monitor/start", response_model=VLMResponse)
def post_start_live_monitor(payload: LiveMonitorRequest) -> VLMResponse:
    return start_live_monitor(payload)
