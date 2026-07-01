from fastapi import APIRouter

from app.schemas import IncidentItem, IntegrationItem
from app.services.incident_service import list_incidents, list_integration_steps

router = APIRouter(prefix="/api", tags=["incidents"])


@router.get("/incidents", response_model=list[IncidentItem])
def get_incidents() -> list[IncidentItem]:
    return list_incidents()


@router.get("/integration", response_model=list[IntegrationItem])
def get_integration() -> list[IntegrationItem]:
    return list_integration_steps()
