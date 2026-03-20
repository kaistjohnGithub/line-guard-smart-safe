"""Unit tests for the safety_zone module."""

import pytest

from src.safety_zone import (
    Point,
    SafetyZone,
    SafetyZoneMonitor,
    ViolationSeverity,
    ZoneType,
)


# ---------------------------------------------------------------------------
# Point
# ---------------------------------------------------------------------------


class TestPoint:
    def test_distance_to_same_point_is_zero(self):
        p = Point(3.0, 4.0)
        assert p.distance_to(p) == 0.0

    def test_distance_to_known_value(self):
        p1 = Point(0.0, 0.0)
        p2 = Point(3.0, 4.0)
        assert p1.distance_to(p2) == pytest.approx(5.0)

    def test_distance_is_symmetric(self):
        p1 = Point(1.0, 2.0)
        p2 = Point(4.0, 6.0)
        assert p1.distance_to(p2) == pytest.approx(p2.distance_to(p1))


# ---------------------------------------------------------------------------
# SafetyZone
# ---------------------------------------------------------------------------


def make_zone(zone_type: ZoneType = ZoneType.DANGER) -> SafetyZone:
    return SafetyZone(
        zone_id="Z001",
        name="Test Zone",
        zone_type=zone_type,
        top_left=Point(0.0, 0.0),
        bottom_right=Point(10.0, 10.0),
    )


class TestSafetyZone:
    def test_contains_interior_point(self):
        zone = make_zone()
        assert zone.contains(Point(5.0, 5.0)) is True

    def test_contains_boundary_point(self):
        zone = make_zone()
        assert zone.contains(Point(0.0, 0.0)) is True
        assert zone.contains(Point(10.0, 10.0)) is True

    def test_does_not_contain_exterior_point(self):
        zone = make_zone()
        assert zone.contains(Point(11.0, 5.0)) is False
        assert zone.contains(Point(5.0, -1.0)) is False

    def test_severity_for_danger_zone(self):
        zone = make_zone(ZoneType.DANGER)
        assert zone.severity == ViolationSeverity.HIGH

    def test_severity_for_restricted_zone(self):
        zone = make_zone(ZoneType.RESTRICTED)
        assert zone.severity == ViolationSeverity.MEDIUM

    def test_severity_for_emergency_exit(self):
        zone = make_zone(ZoneType.EMERGENCY_EXIT)
        assert zone.severity == ViolationSeverity.CRITICAL

    def test_severity_for_safe_zone(self):
        zone = make_zone(ZoneType.SAFE)
        assert zone.severity == ViolationSeverity.LOW


# ---------------------------------------------------------------------------
# SafetyZoneMonitor
# ---------------------------------------------------------------------------


def make_monitor_with_zones() -> SafetyZoneMonitor:
    monitor = SafetyZoneMonitor()
    monitor.add_zone(
        SafetyZone("Z-DANGER", "Laser Area", ZoneType.DANGER, Point(0, 0), Point(5, 5))
    )
    monitor.add_zone(
        SafetyZone(
            "Z-RESTRICTED",
            "Assembly Line",
            ZoneType.RESTRICTED,
            Point(10, 0),
            Point(20, 10),
        )
    )
    monitor.add_zone(
        SafetyZone(
            "Z-SAFE", "Break Room", ZoneType.SAFE, Point(30, 0), Point(40, 10)
        )
    )
    return monitor


class TestSafetyZoneMonitor:
    def test_add_and_get_zone(self):
        monitor = SafetyZoneMonitor()
        zone = make_zone()
        monitor.add_zone(zone)
        assert monitor.get_zone("Z001") is zone

    def test_get_unknown_zone_returns_none(self):
        monitor = SafetyZoneMonitor()
        assert monitor.get_zone("MISSING") is None

    def test_remove_zone_returns_true_when_found(self):
        monitor = make_monitor_with_zones()
        assert monitor.remove_zone("Z-DANGER") is True

    def test_remove_zone_returns_false_when_not_found(self):
        monitor = SafetyZoneMonitor()
        assert monitor.remove_zone("MISSING") is False

    def test_violation_detected_in_danger_zone(self):
        monitor = make_monitor_with_zones()
        violations = monitor.check_position("W001", Point(2.0, 2.0), "2024-01-01T00:00:00Z")
        assert len(violations) == 1
        assert violations[0].zone.zone_id == "Z-DANGER"
        assert violations[0].worker_id == "W001"

    def test_violation_detected_in_restricted_zone(self):
        monitor = make_monitor_with_zones()
        violations = monitor.check_position("W002", Point(15.0, 5.0), "2024-01-01T00:00:00Z")
        assert len(violations) == 1
        assert violations[0].zone.zone_id == "Z-RESTRICTED"

    def test_no_violation_in_safe_zone(self):
        monitor = make_monitor_with_zones()
        violations = monitor.check_position("W003", Point(35.0, 5.0), "2024-01-01T00:00:00Z")
        assert violations == []

    def test_no_violation_outside_all_zones(self):
        monitor = make_monitor_with_zones()
        violations = monitor.check_position("W004", Point(100.0, 100.0), "2024-01-01T00:00:00Z")
        assert violations == []

    def test_violation_ids_are_unique(self):
        monitor = make_monitor_with_zones()
        monitor.check_position("W001", Point(2.0, 2.0), "2024-01-01T00:00:00Z")
        monitor.check_position("W002", Point(2.0, 2.0), "2024-01-01T00:01:00Z")
        ids = [v.violation_id for v in monitor.all_violations]
        assert len(ids) == len(set(ids))

    def test_active_violations_excludes_resolved(self):
        monitor = make_monitor_with_zones()
        violations = monitor.check_position("W001", Point(2.0, 2.0), "2024-01-01T00:00:00Z")
        violations[0].resolve("Worker escorted out")
        assert monitor.active_violations == []

    def test_zones_at_returns_correct_zones(self):
        monitor = make_monitor_with_zones()
        zones = monitor.zones_at(Point(2.0, 2.0))
        assert any(z.zone_id == "Z-DANGER" for z in zones)

    def test_resolve_violation(self):
        monitor = make_monitor_with_zones()
        violations = monitor.check_position("W001", Point(2.0, 2.0), "2024-01-01T00:00:00Z")
        v = violations[0]
        assert not v.resolved
        v.resolve("Cleared")
        assert v.resolved
        assert v.notes == "Cleared"
