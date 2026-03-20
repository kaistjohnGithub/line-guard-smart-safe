"""Unit tests for the alert module."""

import pytest

from src.alert import Alert, AlertManager, AlertPriority, AlertStatus, AlertType


def make_manager() -> AlertManager:
    return AlertManager()


class TestAlert:
    def _make_alert(self, priority: AlertPriority = AlertPriority.WARNING) -> Alert:
        return Alert(
            alert_id="A000001",
            alert_type=AlertType.ZONE_VIOLATION,
            message="Test alert",
            timestamp="2024-01-01T00:00:00Z",
            source_id="W001",
            priority=priority,
        )

    def test_new_alert_is_active(self):
        alert = self._make_alert()
        assert alert.status == AlertStatus.ACTIVE
        assert alert.is_active is True

    def test_acknowledge_transitions_to_acknowledged(self):
        alert = self._make_alert()
        alert.acknowledge("OPS001")
        assert alert.status == AlertStatus.ACKNOWLEDGED
        assert alert.acknowledged_by == "OPS001"

    def test_acknowledge_only_active_alert(self):
        alert = self._make_alert()
        alert.resolve()
        alert.acknowledge("OPS001")
        # Already resolved – acknowledge should have no effect
        assert alert.status == AlertStatus.RESOLVED

    def test_resolve_transitions_to_resolved(self):
        alert = self._make_alert()
        alert.resolve("Issue fixed")
        assert alert.status == AlertStatus.RESOLVED
        assert alert.resolution_notes == "Issue fixed"
        assert alert.is_active is False

    def test_escalate_increases_priority(self):
        alert = self._make_alert(AlertPriority.WARNING)
        alert.escalate()
        assert alert.status == AlertStatus.ESCALATED
        assert alert.priority == AlertPriority.HIGH

    def test_escalate_does_not_exceed_critical(self):
        alert = self._make_alert(AlertPriority.CRITICAL)
        alert.escalate()
        assert alert.priority == AlertPriority.CRITICAL


class TestAlertManager:
    def test_raise_alert_creates_alert(self):
        manager = make_manager()
        alert = manager.raise_alert(
            AlertType.ZONE_VIOLATION,
            "Worker in danger zone",
            "2024-01-01T00:00:00Z",
            "W001",
        )
        assert alert.alert_id is not None
        assert alert.alert_type == AlertType.ZONE_VIOLATION

    def test_alert_ids_are_unique(self):
        manager = make_manager()
        ids = [
            manager.raise_alert(AlertType.ZONE_VIOLATION, "msg", "ts", "src").alert_id
            for _ in range(5)
        ]
        assert len(ids) == len(set(ids))

    def test_default_priority_is_applied(self):
        manager = make_manager()
        alert = manager.raise_alert(AlertType.EMERGENCY, "msg", "ts", "src")
        assert alert.priority == AlertPriority.CRITICAL

    def test_explicit_priority_overrides_default(self):
        manager = make_manager()
        alert = manager.raise_alert(
            AlertType.EMERGENCY, "msg", "ts", "src", priority=AlertPriority.INFO
        )
        assert alert.priority == AlertPriority.INFO

    def test_active_alerts_excludes_resolved(self):
        manager = make_manager()
        a = manager.raise_alert(AlertType.ZONE_VIOLATION, "msg", "ts", "src")
        manager.resolve_alert(a.alert_id, "fixed")
        assert manager.active_alerts == []

    def test_critical_alerts_returns_only_critical(self):
        manager = make_manager()
        manager.raise_alert(AlertType.ZONE_VIOLATION, "low", "ts", "src")
        manager.raise_alert(AlertType.EMERGENCY, "crit", "ts", "src")
        assert len(manager.critical_alerts) == 1

    def test_acknowledge_alert_by_id(self):
        manager = make_manager()
        alert = manager.raise_alert(AlertType.ZONE_VIOLATION, "msg", "ts", "src")
        result = manager.acknowledge_alert(alert.alert_id, "OPS001")
        assert result is True
        assert manager.get_alert(alert.alert_id).status == AlertStatus.ACKNOWLEDGED

    def test_acknowledge_unknown_alert_returns_false(self):
        manager = make_manager()
        assert manager.acknowledge_alert("UNKNOWN", "OPS001") is False

    def test_resolve_alert_by_id(self):
        manager = make_manager()
        alert = manager.raise_alert(AlertType.ZONE_VIOLATION, "msg", "ts", "src")
        result = manager.resolve_alert(alert.alert_id, "resolved")
        assert result is True

    def test_resolve_unknown_alert_returns_false(self):
        manager = make_manager()
        assert manager.resolve_alert("UNKNOWN") is False

    def test_escalate_alert_by_id(self):
        manager = make_manager()
        alert = manager.raise_alert(AlertType.ZONE_VIOLATION, "msg", "ts", "src")
        result = manager.escalate_alert(alert.alert_id)
        assert result is True
        assert manager.get_alert(alert.alert_id).status == AlertStatus.ESCALATED

    def test_handler_is_called_on_new_alert(self):
        manager = make_manager()
        received: list = []
        manager.register_handler(lambda a: received.append(a))
        alert = manager.raise_alert(AlertType.ZONE_VIOLATION, "msg", "ts", "src")
        assert len(received) == 1
        assert received[0] is alert

    def test_unregister_handler(self):
        manager = make_manager()
        received: list = []
        handler = lambda a: received.append(a)
        manager.register_handler(handler)
        manager.unregister_handler(handler)
        manager.raise_alert(AlertType.ZONE_VIOLATION, "msg", "ts", "src")
        assert received == []

    def test_unregister_unknown_handler_returns_false(self):
        manager = make_manager()
        assert manager.unregister_handler(lambda a: None) is False
