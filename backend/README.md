# Backend and VLM Skeleton

This backend skeleton is the bridge between the new frontend shell and the existing Python proof-of-concept in `../vila-safety-poc`.

## Structure

- `app/main.py`: FastAPI application entry
- `app/config.py`: environment and path configuration
- `app/schemas.py`: request and response models
- `app/services/vlm_service.py`: VLM orchestration layer
- `app/services/incident_service.py`: incident and event placeholder store
- `app/api/routes/*.py`: route groups

## Intended flow

1. Frontend sends image, video, or live-monitoring requests.
2. Backend validates input and selects a VLM task.
3. VLM service calls existing PoC scripts or imports their functions.
4. Structured output is returned to the frontend.

## Initial endpoints

- `GET /health`
- `GET /api/incidents`
- `GET /api/integration`
- `POST /api/vlm/analyze-image`
- `POST /api/vlm/analyze-video`
- `POST /api/vlm/live-monitor/start`

## Next implementation step

Replace placeholder responses in `vlm_service.py` with real calls into `../vila-safety-poc`.
