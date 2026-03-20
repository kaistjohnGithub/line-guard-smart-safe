"""LineGuard – main system coordinator for smart factory safety."""

from __future__ import annotations

import datetime
from typing import Dict, List, Optional

from .alert import Alert, AlertManager, AlertPriority, AlertType
from .incident_logger import IncidentLogger, IncidentType
from .safety_zone import (
    Point,
    SafetyZone,
    SafetyZoneMonitor,
    ZoneType,
    ZoneViolation,
)
from .sensor import Sensor, SensorReading, SensorStatus, SensorType


def _utcnow() -> str:
    """Return the current UTC time formatted as an ISO-8601 string."""
    return datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")


class LineGuard:
    """Top-level coordinator for the LineGuard smart factory safety system.

    Responsibilities
    ----------------
    * Accept real-time worker position updates and check for zone violations.
    * Accept sensor readings and evaluate them against safety thresholds.
    * Raise alerts and log incidents automatically when hazards are detected.
    * Provide a unified query interface for the current safety state.
    """

    def __init__(self) -> None:
        self._zone_monitor = SafetyZoneMonitor()
        self._alert_manager = AlertManager()
        self._incident_logger = IncidentLogger()
        self._sensors: Dict[str, Sensor] = {}
        self._emergency_mode: bool = False

    # ------------------------------------------------------------------ #
    # Zone management                                                     #
    # ------------------------------------------------------------------ #

    def add_zone(self, zone: SafetyZone) -> None:
        """Register a safety zone with the system."""
        self._zone_monitor.add_zone(zone)

    def remove_zone(self, zone_id: str) -> bool:
        """Deregister a safety zone.  Returns True if found and removed."""
        return self._zone_monitor.remove_zone(zone_id)

    # ------------------------------------------------------------------ #
    # Sensor management                                                   #
    # ------------------------------------------------------------------ #

    def add_sensor(self, sensor: Sensor) -> None:
        """Register a sensor with the system."""
        self._sensors[sensor.sensor_id] = sensor

    def remove_sensor(self, sensor_id: str) -> bool:
        """Deregister a sensor.  Returns True if found and removed."""
        if sensor_id in self._sensors:
            del self._sensors[sensor_id]
            return True
        return False

    def get_sensor(self, sensor_id: str) -> Optional[Sensor]:
        """Return the sensor with *sensor_id*, or None if not found."""
        return self._sensors.get(sensor_id)

    # ------------------------------------------------------------------ #
    # Worker position tracking                                            #
    # ------------------------------------------------------------------ #

    def report_worker_position(
        self,
        worker_id: str,
        x: float,
        y: float,
        timestamp: Optional[str] = None,
    ) -> List[ZoneViolation]:
        """Report a worker's position and evaluate zone safety.

        Returns a (possibly empty) list of new ZoneViolation objects.
        Automatically raises alerts for any violations detected.
        """
        ts = timestamp or _utcnow()
        location = Point(x, y)
        violations = self._zone_monitor.check_position(worker_id, location, ts)

        for violation in violations:
            alert_type = (
                AlertType.EMERGENCY
                if violation.zone.zone_type == ZoneType.DANGER
                else AlertType.ZONE_VIOLATION
            )
            self._alert_manager.raise_alert(
                alert_type=alert_type,
                message=(
                    f"Worker {worker_id} entered {violation.zone.zone_type.value} "
                    f"zone '{violation.zone.name}' at ({x:.2f}, {y:.2f})"
                ),
                timestamp=ts,
                source_id=worker_id,
            )

            # Log a zone-breach incident for restricted / danger zones
            if violation.zone.zone_type in (ZoneType.RESTRICTED, ZoneType.DANGER):
                self._incident_logger.log_incident(
                    incident_type=IncidentType.ZONE_BREACH,
                    description=(
                        f"Worker {worker_id} breached "
                        f"{violation.zone.zone_type.value} zone '{violation.zone.name}'"
                    ),
                    timestamp=ts,
                    reported_by="LineGuard-System",
                    zone_id=violation.zone.zone_id,
                    worker_ids=[worker_id],
                )

        return violations

    # ------------------------------------------------------------------ #
    # Sensor reading processing                                           #
    # ------------------------------------------------------------------ #

    def process_sensor_reading(
        self,
        sensor_id: str,
        value: float,
        unit: str,
        timestamp: Optional[str] = None,
    ) -> Optional[Alert]:
        """Process a sensor reading and raise an alert if unsafe.

        Returns the Alert raised, or None if the reading is within safe limits
        or the sensor is not registered.
        """
        ts = timestamp or _utcnow()
        sensor = self._sensors.get(sensor_id)
        if sensor is None:
            return None

        reading = sensor.record_reading(value, unit, ts)

        if not sensor.is_reading_safe(reading):
            alert_type = self._sensor_alert_type(sensor.sensor_type)
            alert = self._alert_manager.raise_alert(
                alert_type=alert_type,
                message=(
                    f"Sensor {sensor_id} ({sensor.sensor_type.value}) "
                    f"reading {value} {unit} exceeds safe threshold "
                    f"in zone '{sensor.zone_id}'"
                ),
                timestamp=ts,
                source_id=sensor_id,
            )

            # Automatically trigger emergency mode for critical sensor types
            if alert_type in (AlertType.FIRE, AlertType.GAS_LEAK):
                self.trigger_emergency(reason=alert.message, timestamp=ts)

            return alert
        return None

    def report_sensor_offline(
        self, sensor_id: str, timestamp: Optional[str] = None
    ) -> Alert:
        """Report that a sensor has gone offline and raise an alert."""
        ts = timestamp or _utcnow()
        sensor = self._sensors.get(sensor_id)
        if sensor:
            sensor.set_status(SensorStatus.OFFLINE)
        return self._alert_manager.raise_alert(
            alert_type=AlertType.SENSOR_OFFLINE,
            message=f"Sensor {sensor_id} is offline",
            timestamp=ts,
            source_id=sensor_id,
        )

    # ------------------------------------------------------------------ #
    # Emergency management                                                #
    # ------------------------------------------------------------------ #

    def trigger_emergency(
        self, reason: str = "", timestamp: Optional[str] = None
    ) -> Alert:
        """Activate emergency mode and raise a CRITICAL alert."""
        ts = timestamp or _utcnow()
        self._emergency_mode = True
        return self._alert_manager.raise_alert(
            alert_type=AlertType.EMERGENCY,
            message=f"EMERGENCY: {reason}" if reason else "EMERGENCY activated",
            timestamp=ts,
            source_id="LineGuard-System",
            priority=AlertPriority.CRITICAL,
        )

    def clear_emergency(self) -> None:
        """Deactivate emergency mode."""
        self._emergency_mode = False

    @property
    def in_emergency(self) -> bool:
        """Return True while emergency mode is active."""
        return self._emergency_mode

    # ------------------------------------------------------------------ #
    # Alert management pass-through                                       #
    # ------------------------------------------------------------------ #

    def acknowledge_alert(self, alert_id: str, operator_id: str) -> bool:
        """Acknowledge an alert by ID.  Returns True if found."""
        return self._alert_manager.acknowledge_alert(alert_id, operator_id)

    def resolve_alert(self, alert_id: str, notes: str = "") -> bool:
        """Resolve an alert by ID.  Returns True if found."""
        return self._alert_manager.resolve_alert(alert_id, notes)

    # ------------------------------------------------------------------ #
    # Incident management pass-through                                    #
    # ------------------------------------------------------------------ #

    def log_incident(
        self,
        incident_type: IncidentType,
        description: str,
        reported_by: str,
        zone_id: Optional[str] = None,
        worker_ids: Optional[List[str]] = None,
        timestamp: Optional[str] = None,
    ):
        """Manually log a safety incident."""
        ts = timestamp or _utcnow()
        return self._incident_logger.log_incident(
            incident_type=incident_type,
            description=description,
            timestamp=ts,
            reported_by=reported_by,
            zone_id=zone_id,
            worker_ids=worker_ids,
        )

    # ------------------------------------------------------------------ #
    # Status and reporting                                                #
    # ------------------------------------------------------------------ #

    def safety_status(self) -> dict:
        """Return a summary dict of the current safety state."""
        return {
            "emergency_mode": self._emergency_mode,
            "active_alerts": len(self._alert_manager.active_alerts),
            "critical_alerts": len(self._alert_manager.critical_alerts),
            "open_incidents": len(self._incident_logger.open_incidents),
            "active_zone_violations": len(self._zone_monitor.active_violations),
            "registered_sensors": len(self._sensors),
        }

    def generate_compliance_report(self, period_start: str, period_end: str):
        """Generate a compliance report for the given period."""
        return self._incident_logger.generate_compliance_report(
            period_start=period_start,
            period_end=period_end,
            total_zone_violations=len(self._zone_monitor.all_violations),
            total_alerts_raised=len(self._alert_manager.all_alerts),
            critical_alerts=len(self._alert_manager.critical_alerts),
        )

    # ------------------------------------------------------------------ #
    # Internal helpers                                                    #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _sensor_alert_type(sensor_type: SensorType) -> AlertType:
        mapping = {
            SensorType.SMOKE: AlertType.FIRE,
            SensorType.GAS: AlertType.GAS_LEAK,
            SensorType.TEMPERATURE: AlertType.SENSOR_THRESHOLD,
            SensorType.PROXIMITY: AlertType.SENSOR_THRESHOLD,
            SensorType.VIBRATION: AlertType.SENSOR_THRESHOLD,
            SensorType.MOTION: AlertType.SENSOR_THRESHOLD,
        }
        return mapping.get(sensor_type, AlertType.SENSOR_THRESHOLD)
