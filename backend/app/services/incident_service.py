from app.schemas import IncidentItem, IntegrationItem


def list_incidents() -> list[IncidentItem]:
    return [
        IncidentItem(
            incident_id="INC-001",
            severity="critical",
            title="Hand zone near active press cycle",
            area="Assembly / Press",
            timestamp="2026-03-17T14:22:19+07:00",
            source="mock",
        ),
        IncidentItem(
            incident_id="INC-002",
            severity="high",
            title="Missing face shield during sampling",
            area="Sampling Station",
            timestamp="2026-03-17T13:45:11+07:00",
            source="mock",
        ),
        IncidentItem(
            incident_id="INC-003",
            severity="medium",
            title="Oil spill near welding cell",
            area="Assembly B",
            timestamp="2026-03-17T12:10:34+07:00",
            source="mock",
        ),
    ]


def list_integration_steps() -> list[IntegrationItem]:
    return [
        IntegrationItem(
            layer="Frontend",
            status="in-progress",
            detail="Structured project shell created from the original HTML template.",
        ),
        IntegrationItem(
            layer="Backend API",
            status="in-progress",
            detail="FastAPI skeleton added for incidents, VLM tasks, and integration metadata.",
        ),
        IntegrationItem(
            layer="VLM Service",
            status="planned",
            detail="Wrap safety_inspector.py, describe_video.py, and live_demo.py behind service methods.",
        ),
        IntegrationItem(
            layer="Persistence",
            status="planned",
            detail="Store incidents, acknowledgements, SOP checks, and operator review outcomes.",
        ),
    ]
