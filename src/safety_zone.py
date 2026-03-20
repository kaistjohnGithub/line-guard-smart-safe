"""Safety zone definitions and violation detection for smart factory monitoring."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional, Tuple


class ZoneType(Enum):
    """Classification of safety zones on the factory floor."""

    SAFE = "safe"
    RESTRICTED = "restricted"
    DANGER = "danger"
    EMERGENCY_EXIT = "emergency_exit"


class ViolationSeverity(Enum):
    """Severity levels for zone violations."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class Point:
    """A two-dimensional coordinate on the factory floor (in metres)."""

    x: float
    y: float

    def distance_to(self, other: "Point") -> float:
        """Return the Euclidean distance to *other*."""
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5


@dataclass
class SafetyZone:
    """Rectangular safety zone defined by two corner points."""

    zone_id: str
    name: str
    zone_type: ZoneType
    top_left: Point
    bottom_right: Point

    def contains(self, point: Point) -> bool:
        """Return True if *point* lies within this zone."""
        return (
            self.top_left.x <= point.x <= self.bottom_right.x
            and self.top_left.y <= point.y <= self.bottom_right.y
        )

    @property
    def severity(self) -> ViolationSeverity:
        """Return the default violation severity for this zone type."""
        mapping = {
            ZoneType.SAFE: ViolationSeverity.LOW,
            ZoneType.RESTRICTED: ViolationSeverity.MEDIUM,
            ZoneType.DANGER: ViolationSeverity.HIGH,
            ZoneType.EMERGENCY_EXIT: ViolationSeverity.CRITICAL,
        }
        return mapping[self.zone_type]


@dataclass
class ZoneViolation:
    """Record of a safety zone violation by a worker or object."""

    violation_id: str
    zone: SafetyZone
    worker_id: str
    location: Point
    severity: ViolationSeverity
    timestamp: str
    resolved: bool = False
    notes: str = ""

    def resolve(self, notes: str = "") -> None:
        """Mark this violation as resolved."""
        self.resolved = True
        self.notes = notes


class SafetyZoneMonitor:
    """Monitor a collection of safety zones and detect violations."""

    def __init__(self) -> None:
        self._zones: List[SafetyZone] = []
        self._violations: List[ZoneViolation] = []
        self._violation_counter: int = 0

    def add_zone(self, zone: SafetyZone) -> None:
        """Register a safety zone with the monitor."""
        self._zones.append(zone)

    def remove_zone(self, zone_id: str) -> bool:
        """Deregister a zone by its ID.  Returns True if found and removed."""
        before = len(self._zones)
        self._zones = [z for z in self._zones if z.zone_id != zone_id]
        return len(self._zones) < before

    def get_zone(self, zone_id: str) -> Optional[SafetyZone]:
        """Return the zone with *zone_id*, or None if not found."""
        for zone in self._zones:
            if zone.zone_id == zone_id:
                return zone
        return None

    def check_position(
        self, worker_id: str, location: Point, timestamp: str
    ) -> List[ZoneViolation]:
        """Check *location* against all registered zones.

        A violation is recorded when a worker enters a RESTRICTED, DANGER,
        or EMERGENCY_EXIT zone.  Returns the list of new violations created.
        """
        new_violations: List[ZoneViolation] = []
        for zone in self._zones:
            if zone.zone_type == ZoneType.SAFE:
                continue
            if zone.contains(location):
                self._violation_counter += 1
                violation = ZoneViolation(
                    violation_id=f"V{self._violation_counter:06d}",
                    zone=zone,
                    worker_id=worker_id,
                    location=location,
                    severity=zone.severity,
                    timestamp=timestamp,
                )
                self._violations.append(violation)
                new_violations.append(violation)
        return new_violations

    @property
    def active_violations(self) -> List[ZoneViolation]:
        """Return all unresolved violations."""
        return [v for v in self._violations if not v.resolved]

    @property
    def all_violations(self) -> List[ZoneViolation]:
        """Return all violations (resolved and unresolved)."""
        return list(self._violations)

    def zones_at(self, location: Point) -> List[SafetyZone]:
        """Return every zone that contains *location*."""
        return [z for z in self._zones if z.contains(location)]
