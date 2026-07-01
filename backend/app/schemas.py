from typing import Literal

from pydantic import BaseModel, Field


Severity = Literal["info", "low", "medium", "high", "critical"]
MonitorSource = Literal["demo", "webcam", "rtsp"]
AnalyzeTask = Literal["general-safety", "ppe-check", "sop-check", "near-miss"]


class HealthResponse(BaseModel):
    status: str
    app: str
    version: str


class IncidentItem(BaseModel):
    incident_id: str
    severity: Severity
    title: str
    area: str
    timestamp: str
    source: str


class IntegrationItem(BaseModel):
    layer: str
    status: str
    detail: str


class ImageAnalyzeRequest(BaseModel):
    image_path: str = Field(..., description="Absolute or project-relative image path")
    task: AnalyzeTask = "general-safety"
    prompt: str | None = None
    model_name: str | None = None


class VideoAnalyzeRequest(BaseModel):
    video_path: str = Field(..., description="Absolute or project-relative video path")
    interval_sec: float = 3.0
    max_frames: int = 12
    prompt: str | None = None
    model_name: str | None = None


class LiveMonitorRequest(BaseModel):
    source: MonitorSource = "demo"
    webcam_id: int = 0
    rtsp_url: str | None = None
    fps: float = 0.5
    iterations: int = 20
    model_name: str | None = None


class VLMResponse(BaseModel):
    mode: str
    status: str
    model: str
    summary: str
    raw_source: str
    result: dict
