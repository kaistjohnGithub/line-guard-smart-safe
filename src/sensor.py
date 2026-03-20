"""Sensor data models for smart factory safety monitoring."""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Optional


class SensorType(Enum):
    """Supported sensor types."""

    MOTION = "motion"
    TEMPERATURE = "temperature"
    GAS = "gas"
    PROXIMITY = "proximity"
    VIBRATION = "vibration"
    SMOKE = "smoke"


class SensorStatus(Enum):
    """Operational status of a sensor."""

    ONLINE = "online"
    OFFLINE = "offline"
    FAULT = "fault"
    CALIBRATING = "calibrating"


@dataclass
class SensorReading:
    """A single reading from a factory sensor."""

    sensor_id: str
    sensor_type: SensorType
    value: float
    unit: str
    timestamp: str
    zone_id: Optional[str] = None

    def is_within_threshold(self, low: float, high: float) -> bool:
        """Return True if the reading value is between *low* and *high* (inclusive)."""
        return low <= self.value <= high


@dataclass
class Sensor:
    """A physical or virtual sensor attached to a production line."""

    sensor_id: str
    sensor_type: SensorType
    zone_id: str
    location_description: str
    status: SensorStatus = SensorStatus.ONLINE
    _last_reading: Optional[SensorReading] = None

    # ------------------------------------------------------------------ #
    # Default safety thresholds (low, high)                               #
    # ------------------------------------------------------------------ #
    THRESHOLDS: dict = None  # populated in __post_init__

    def __post_init__(self) -> None:
        self.THRESHOLDS = {
            SensorType.TEMPERATURE: (0.0, 60.0),   # degrees Celsius
            SensorType.GAS: (0.0, 25.0),            # ppm (lower explosive limit %)
            SensorType.PROXIMITY: (0.5, float("inf")),  # metres – min safe distance
            SensorType.VIBRATION: (0.0, 5.0),       # m/s²
            SensorType.SMOKE: (0.0, 10.0),          # optical density %
            SensorType.MOTION: (0.0, 1.0),          # binary 0/1; any motion in zone
        }

    def record_reading(self, value: float, unit: str, timestamp: str) -> SensorReading:
        """Record a new reading and return the SensorReading object."""
        reading = SensorReading(
            sensor_id=self.sensor_id,
            sensor_type=self.sensor_type,
            value=value,
            unit=unit,
            timestamp=timestamp,
            zone_id=self.zone_id,
        )
        self._last_reading = reading
        return reading

    @property
    def last_reading(self) -> Optional[SensorReading]:
        """Return the most recent reading, or None if no reading has been taken."""
        return self._last_reading

    def is_reading_safe(self, reading: SensorReading) -> bool:
        """Return True if *reading* is within the safe threshold for this sensor type."""
        if self.sensor_type not in self.THRESHOLDS:
            return True
        low, high = self.THRESHOLDS[self.sensor_type]
        return reading.is_within_threshold(low, high)

    def set_status(self, status: SensorStatus) -> None:
        """Update the operational status of this sensor."""
        self.status = status
