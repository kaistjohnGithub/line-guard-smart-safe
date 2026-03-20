"""Incident logging and safety compliance reporting."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional


class IncidentType(Enum):
    """Classification of safety incidents."""

    NEAR_MISS = "near_miss"
    MINOR_INJURY = "minor_injury"
    MAJOR_INJURY = "major_injury"
    EQUIPMENT_DAMAGE = "equipment_damage"
    FIRE = "fire"
    CHEMICAL_SPILL = "chemical_spill"
    GAS_LEAK = "gas_leak"
    ZONE_BREACH = "zone_breach"


class IncidentStatus(Enum):
    """Status of an incident report."""

    OPEN = "open"
    UNDER_INVESTIGATION = "under_investigation"
    CLOSED = "closed"
    ESCALATED = "escalated"


@dataclass
class Incident:
    """Record of a safety incident on the factory floor."""

    incident_id: str
    incident_type: IncidentType
    description: str
    timestamp: str
    reported_by: str
    zone_id: Optional[str] = None
    worker_ids: List[str] = field(default_factory=list)
    status: IncidentStatus = IncidentStatus.OPEN
    root_cause: str = ""
    corrective_actions: List[str] = field(default_factory=list)
    closed_at: Optional[str] = None

    def add_corrective_action(self, action: str) -> None:
        """Append a corrective action to this incident."""
        self.corrective_actions.append(action)

    def close(self, root_cause: str, closed_at: str) -> None:
        """Close this incident with a root cause and closing timestamp."""
        self.root_cause = root_cause
        self.status = IncidentStatus.CLOSED
        self.closed_at = closed_at

    def escalate(self) -> None:
        """Escalate this incident for higher-level review."""
        self.status = IncidentStatus.ESCALATED

    def start_investigation(self) -> None:
        """Transition this incident to under-investigation status."""
        if self.status == IncidentStatus.OPEN:
            self.status = IncidentStatus.UNDER_INVESTIGATION


@dataclass
class ComplianceReport:
    """Summary of safety compliance over a reporting period."""

    period_start: str
    period_end: str
    total_incidents: int
    open_incidents: int
    closed_incidents: int
    escalated_incidents: int
    incidents_by_type: Dict[str, int]
    total_zone_violations: int
    total_alerts_raised: int
    critical_alerts: int
    compliance_score: float  # 0.0 – 100.0

    @property
    def is_compliant(self) -> bool:
        """Return True when the compliance score meets the minimum threshold (80 %)."""
        return self.compliance_score >= 80.0


class IncidentLogger:
    """Log, track, and report on factory safety incidents."""

    def __init__(self) -> None:
        self._incidents: List[Incident] = []
        self._incident_counter: int = 0

    def log_incident(
        self,
        incident_type: IncidentType,
        description: str,
        timestamp: str,
        reported_by: str,
        zone_id: Optional[str] = None,
        worker_ids: Optional[List[str]] = None,
    ) -> Incident:
        """Create and store a new incident record."""
        self._incident_counter += 1
        incident = Incident(
            incident_id=f"INC{self._incident_counter:06d}",
            incident_type=incident_type,
            description=description,
            timestamp=timestamp,
            reported_by=reported_by,
            zone_id=zone_id,
            worker_ids=worker_ids or [],
        )
        self._incidents.append(incident)
        return incident

    def get_incident(self, incident_id: str) -> Optional[Incident]:
        """Return the incident with *incident_id*, or None if not found."""
        for incident in self._incidents:
            if incident.incident_id == incident_id:
                return incident
        return None

    @property
    def open_incidents(self) -> List[Incident]:
        """Return all incidents that are not yet closed."""
        return [
            i for i in self._incidents if i.status != IncidentStatus.CLOSED
        ]

    @property
    def all_incidents(self) -> List[Incident]:
        """Return every incident regardless of status."""
        return list(self._incidents)

    def generate_compliance_report(
        self,
        period_start: str,
        period_end: str,
        total_zone_violations: int = 0,
        total_alerts_raised: int = 0,
        critical_alerts: int = 0,
    ) -> ComplianceReport:
        """Generate a compliance report for the given period.

        The compliance score is calculated as::

            100 – (open_incidents * 5) – (critical_alerts * 10)

        clamped to [0, 100].
        """
        total = len(self._incidents)
        open_count = len(self.open_incidents)
        closed_count = sum(
            1 for i in self._incidents if i.status == IncidentStatus.CLOSED
        )
        escalated_count = sum(
            1 for i in self._incidents if i.status == IncidentStatus.ESCALATED
        )

        incidents_by_type: Dict[str, int] = {}
        for incident in self._incidents:
            key = incident.incident_type.value
            incidents_by_type[key] = incidents_by_type.get(key, 0) + 1

        raw_score = 100.0 - (open_count * 5.0) - (critical_alerts * 10.0)
        compliance_score = max(0.0, min(100.0, raw_score))

        return ComplianceReport(
            period_start=period_start,
            period_end=period_end,
            total_incidents=total,
            open_incidents=open_count,
            closed_incidents=closed_count,
            escalated_incidents=escalated_count,
            incidents_by_type=incidents_by_type,
            total_zone_violations=total_zone_violations,
            total_alerts_raised=total_alerts_raised,
            critical_alerts=critical_alerts,
            compliance_score=compliance_score,
        )
