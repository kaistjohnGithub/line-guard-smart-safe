"""Unit tests for the incident_logger module."""

import pytest

from src.incident_logger import (
    IncidentLogger,
    IncidentStatus,
    IncidentType,
)


def make_logger() -> IncidentLogger:
    return IncidentLogger()


class TestIncident:
    def _make_incident(self, logger: IncidentLogger):
        return logger.log_incident(
            incident_type=IncidentType.ZONE_BREACH,
            description="Worker in restricted zone",
            timestamp="2024-01-01T00:00:00Z",
            reported_by="LineGuard-System",
            zone_id="Z001",
            worker_ids=["W001"],
        )

    def test_new_incident_is_open(self):
        logger = make_logger()
        incident = self._make_incident(logger)
        assert incident.status == IncidentStatus.OPEN

    def test_start_investigation_transitions_status(self):
        logger = make_logger()
        incident = self._make_incident(logger)
        incident.start_investigation()
        assert incident.status == IncidentStatus.UNDER_INVESTIGATION

    def test_start_investigation_only_from_open(self):
        logger = make_logger()
        incident = self._make_incident(logger)
        incident.escalate()
        incident.start_investigation()
        # Should not change from ESCALATED to UNDER_INVESTIGATION
        assert incident.status == IncidentStatus.ESCALATED

    def test_close_incident(self):
        logger = make_logger()
        incident = self._make_incident(logger)
        incident.close("Root cause found", "2024-01-02T00:00:00Z")
        assert incident.status == IncidentStatus.CLOSED
        assert incident.root_cause == "Root cause found"
        assert incident.closed_at == "2024-01-02T00:00:00Z"

    def test_escalate_incident(self):
        logger = make_logger()
        incident = self._make_incident(logger)
        incident.escalate()
        assert incident.status == IncidentStatus.ESCALATED

    def test_add_corrective_action(self):
        logger = make_logger()
        incident = self._make_incident(logger)
        incident.add_corrective_action("Retrain worker")
        incident.add_corrective_action("Install physical barrier")
        assert len(incident.corrective_actions) == 2


class TestIncidentLogger:
    def test_log_incident_returns_incident(self):
        logger = make_logger()
        incident = logger.log_incident(
            IncidentType.NEAR_MISS, "desc", "ts", "reporter"
        )
        assert incident.incident_id is not None

    def test_incident_ids_are_unique(self):
        logger = make_logger()
        ids = [
            logger.log_incident(IncidentType.NEAR_MISS, "d", "ts", "r").incident_id
            for _ in range(5)
        ]
        assert len(ids) == len(set(ids))

    def test_get_incident_by_id(self):
        logger = make_logger()
        incident = logger.log_incident(IncidentType.NEAR_MISS, "d", "ts", "r")
        assert logger.get_incident(incident.incident_id) is incident

    def test_get_unknown_incident_returns_none(self):
        logger = make_logger()
        assert logger.get_incident("MISSING") is None

    def test_open_incidents_excludes_closed(self):
        logger = make_logger()
        inc = logger.log_incident(IncidentType.NEAR_MISS, "d", "ts", "r")
        inc.close("root", "ts2")
        assert logger.open_incidents == []

    def test_all_incidents_includes_closed(self):
        logger = make_logger()
        inc = logger.log_incident(IncidentType.NEAR_MISS, "d", "ts", "r")
        inc.close("root", "ts2")
        assert inc in logger.all_incidents

    def test_compliance_report_no_incidents(self):
        logger = make_logger()
        report = logger.generate_compliance_report("2024-01-01", "2024-01-31")
        assert report.total_incidents == 0
        assert report.compliance_score == pytest.approx(100.0)

    def test_compliance_report_reduces_score_for_open_incidents(self):
        logger = make_logger()
        for _ in range(4):
            logger.log_incident(IncidentType.NEAR_MISS, "d", "ts", "r")
        report = logger.generate_compliance_report("2024-01-01", "2024-01-31")
        # 4 open incidents × 5 each = -20 → score 80
        assert report.compliance_score == pytest.approx(80.0)

    def test_compliance_report_is_compliant_at_80(self):
        logger = make_logger()
        report = logger.generate_compliance_report("2024-01-01", "2024-01-31")
        assert report.is_compliant is True

    def test_compliance_report_not_compliant_below_80(self):
        logger = make_logger()
        for _ in range(5):  # 5 × 5 = 25 → score 75
            logger.log_incident(IncidentType.NEAR_MISS, "d", "ts", "r")
        report = logger.generate_compliance_report("2024-01-01", "2024-01-31")
        assert report.is_compliant is False

    def test_compliance_score_never_negative(self):
        logger = make_logger()
        for _ in range(50):
            logger.log_incident(IncidentType.NEAR_MISS, "d", "ts", "r")
        report = logger.generate_compliance_report(
            "2024-01-01", "2024-01-31", critical_alerts=100
        )
        assert report.compliance_score >= 0.0

    def test_incidents_by_type_in_report(self):
        logger = make_logger()
        logger.log_incident(IncidentType.FIRE, "d", "ts", "r")
        logger.log_incident(IncidentType.FIRE, "d", "ts", "r")
        logger.log_incident(IncidentType.GAS_LEAK, "d", "ts", "r")
        report = logger.generate_compliance_report("2024-01-01", "2024-01-31")
        assert report.incidents_by_type.get("fire") == 2
        assert report.incidents_by_type.get("gas_leak") == 1
