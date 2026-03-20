"""Integration tests for the LineGuard system coordinator."""

import pytest

from src.alert import AlertPriority, AlertType
from src.incident_logger import IncidentType
from src.line_guard import LineGuard
from src.safety_zone import Point, SafetyZone, ZoneType
from src.sensor import Sensor, SensorType


def make_system() -> LineGuard:
    """Return a LineGuard instance pre-configured with representative zones and sensors."""
    system = LineGuard()

    system.add_zone(
        SafetyZone(
            "Z-DANGER",
            "Robotic Arm Area",
            ZoneType.DANGER,
            Point(0, 0),
            Point(5, 5),
        )
    )
    system.add_zone(
        SafetyZone(
            "Z-RESTRICTED",
            "Assembly Line",
            ZoneType.RESTRICTED,
            Point(10, 0),
            Point(20, 10),
        )
    )
    system.add_zone(
        SafetyZone(
            "Z-SAFE",
            "Break Room",
            ZoneType.SAFE,
            Point(30, 0),
            Point(40, 10),
        )
    )

    system.add_sensor(
        Sensor("TEMP-01", SensorType.TEMPERATURE, "Z-DANGER", "Robotic arm cabinet")
    )
    system.add_sensor(
        Sensor("GAS-01", SensorType.GAS, "Z-RESTRICTED", "Near welding station")
    )
    system.add_sensor(
        Sensor("SMOKE-01", SensorType.SMOKE, "Z-DANGER", "Ceiling sprinkler zone")
    )

    return system


class TestLineGuardZoneMonitoring:
    def test_worker_in_danger_zone_raises_alert(self):
        system = make_system()
        violations = system.report_worker_position("W001", 2.0, 2.0, "2024-01-01T00:00:00Z")
        assert len(violations) == 1
        status = system.safety_status()
        assert status["active_alerts"] >= 1

    def test_worker_in_restricted_zone_logs_incident(self):
        system = make_system()
        system.report_worker_position("W002", 15.0, 5.0, "2024-01-01T00:00:00Z")
        status = system.safety_status()
        assert status["open_incidents"] >= 1

    def test_worker_in_safe_zone_no_violation(self):
        system = make_system()
        violations = system.report_worker_position("W003", 35.0, 5.0, "2024-01-01T00:00:00Z")
        assert violations == []
        status = system.safety_status()
        assert status["active_alerts"] == 0

    def test_worker_outside_all_zones_no_violation(self):
        system = make_system()
        violations = system.report_worker_position("W004", 100.0, 100.0, "ts")
        assert violations == []

    def test_remove_zone_stops_violations(self):
        system = make_system()
        system.remove_zone("Z-DANGER")
        violations = system.report_worker_position("W001", 2.0, 2.0, "ts")
        assert violations == []


class TestLineGuardSensorMonitoring:
    def test_normal_temperature_reading_raises_no_alert(self):
        system = make_system()
        alert = system.process_sensor_reading("TEMP-01", 30.0, "C", "ts")
        assert alert is None

    def test_high_temperature_reading_raises_alert(self):
        system = make_system()
        alert = system.process_sensor_reading("TEMP-01", 90.0, "C", "ts")
        assert alert is not None
        assert alert.alert_type == AlertType.SENSOR_THRESHOLD

    def test_high_gas_reading_raises_gas_leak_alert(self):
        system = make_system()
        alert = system.process_sensor_reading("GAS-01", 50.0, "ppm", "ts")
        assert alert is not None
        assert alert.alert_type == AlertType.GAS_LEAK

    def test_high_gas_triggers_emergency_mode(self):
        system = make_system()
        system.process_sensor_reading("GAS-01", 50.0, "ppm", "ts")
        assert system.in_emergency is True

    def test_smoke_reading_triggers_emergency_mode(self):
        system = make_system()
        system.process_sensor_reading("SMOKE-01", 20.0, "%", "ts")
        assert system.in_emergency is True

    def test_unknown_sensor_returns_none(self):
        system = make_system()
        result = system.process_sensor_reading("UNKNOWN", 999.0, "C", "ts")
        assert result is None

    def test_remove_sensor(self):
        system = make_system()
        assert system.remove_sensor("TEMP-01") is True
        assert system.get_sensor("TEMP-01") is None

    def test_remove_unknown_sensor_returns_false(self):
        system = make_system()
        assert system.remove_sensor("MISSING") is False

    def test_sensor_offline_alert(self):
        system = make_system()
        alert = system.report_sensor_offline("TEMP-01", "ts")
        assert alert.alert_type == AlertType.SENSOR_OFFLINE


class TestLineGuardEmergency:
    def test_trigger_emergency_activates_mode(self):
        system = make_system()
        system.trigger_emergency("Test emergency", "ts")
        assert system.in_emergency is True

    def test_clear_emergency_deactivates_mode(self):
        system = make_system()
        system.trigger_emergency("Test", "ts")
        system.clear_emergency()
        assert system.in_emergency is False

    def test_emergency_alert_is_critical_priority(self):
        system = make_system()
        alert = system.trigger_emergency("Explosion risk", "ts")
        assert alert.priority == AlertPriority.CRITICAL


class TestLineGuardAlertManagement:
    def test_acknowledge_alert(self):
        system = make_system()
        violations = system.report_worker_position("W001", 2.0, 2.0, "ts")
        # Retrieve the alert that was raised
        from src.alert import AlertStatus
        active = [a for a in system._alert_manager.active_alerts]
        assert len(active) >= 1
        result = system.acknowledge_alert(active[0].alert_id, "OPS001")
        assert result is True

    def test_resolve_alert(self):
        system = make_system()
        system.report_worker_position("W001", 2.0, 2.0, "ts")
        active = system._alert_manager.active_alerts
        alert_id = active[0].alert_id
        result = system.resolve_alert(alert_id, "Worker removed from zone")
        assert result is True


class TestLineGuardComplianceReport:
    def test_compliance_report_generated(self):
        system = make_system()
        report = system.generate_compliance_report("2024-01-01", "2024-01-31")
        assert report.period_start == "2024-01-01"
        assert report.period_end == "2024-01-31"

    def test_compliance_report_includes_violations(self):
        system = make_system()
        system.report_worker_position("W001", 2.0, 2.0, "ts")
        report = system.generate_compliance_report("2024-01-01", "2024-01-31")
        assert report.total_zone_violations >= 1

    def test_safety_status_dict_keys(self):
        system = make_system()
        status = system.safety_status()
        for key in (
            "emergency_mode",
            "active_alerts",
            "critical_alerts",
            "open_incidents",
            "active_zone_violations",
            "registered_sensors",
        ):
            assert key in status
