"""Unit tests for the sensor module."""

import pytest

from src.sensor import Sensor, SensorReading, SensorStatus, SensorType


def make_sensor(sensor_type: SensorType = SensorType.TEMPERATURE) -> Sensor:
    return Sensor(
        sensor_id="S001",
        sensor_type=sensor_type,
        zone_id="Z001",
        location_description="Line A – junction box",
    )


class TestSensorReading:
    def test_within_threshold_returns_true(self):
        reading = SensorReading("S001", SensorType.TEMPERATURE, 25.0, "C", "2024-01-01T00:00:00Z")
        assert reading.is_within_threshold(0.0, 60.0) is True

    def test_above_threshold_returns_false(self):
        reading = SensorReading("S001", SensorType.TEMPERATURE, 70.0, "C", "2024-01-01T00:00:00Z")
        assert reading.is_within_threshold(0.0, 60.0) is False

    def test_below_threshold_returns_false(self):
        reading = SensorReading("S001", SensorType.TEMPERATURE, -5.0, "C", "2024-01-01T00:00:00Z")
        assert reading.is_within_threshold(0.0, 60.0) is False

    def test_exactly_at_boundary_is_within(self):
        reading = SensorReading("S001", SensorType.TEMPERATURE, 60.0, "C", "2024-01-01T00:00:00Z")
        assert reading.is_within_threshold(0.0, 60.0) is True


class TestSensor:
    def test_record_reading_returns_sensor_reading(self):
        sensor = make_sensor()
        reading = sensor.record_reading(30.0, "C", "2024-01-01T00:00:00Z")
        assert isinstance(reading, SensorReading)
        assert reading.value == 30.0
        assert reading.sensor_id == "S001"

    def test_last_reading_is_none_before_first_reading(self):
        sensor = make_sensor()
        assert sensor.last_reading is None

    def test_last_reading_updated_after_record(self):
        sensor = make_sensor()
        sensor.record_reading(25.0, "C", "2024-01-01T00:00:00Z")
        assert sensor.last_reading is not None
        assert sensor.last_reading.value == 25.0

    def test_safe_reading_within_threshold(self):
        sensor = make_sensor(SensorType.TEMPERATURE)
        reading = sensor.record_reading(40.0, "C", "2024-01-01T00:00:00Z")
        assert sensor.is_reading_safe(reading) is True

    def test_unsafe_reading_above_threshold(self):
        sensor = make_sensor(SensorType.TEMPERATURE)
        reading = sensor.record_reading(100.0, "C", "2024-01-01T00:00:00Z")
        assert sensor.is_reading_safe(reading) is False

    def test_gas_sensor_unsafe_above_threshold(self):
        sensor = make_sensor(SensorType.GAS)
        reading = sensor.record_reading(50.0, "ppm", "2024-01-01T00:00:00Z")
        assert sensor.is_reading_safe(reading) is False

    def test_gas_sensor_safe_within_threshold(self):
        sensor = make_sensor(SensorType.GAS)
        reading = sensor.record_reading(10.0, "ppm", "2024-01-01T00:00:00Z")
        assert sensor.is_reading_safe(reading) is True

    def test_proximity_sensor_safe(self):
        sensor = make_sensor(SensorType.PROXIMITY)
        reading = sensor.record_reading(2.0, "m", "2024-01-01T00:00:00Z")
        assert sensor.is_reading_safe(reading) is True

    def test_proximity_sensor_unsafe_too_close(self):
        sensor = make_sensor(SensorType.PROXIMITY)
        reading = sensor.record_reading(0.1, "m", "2024-01-01T00:00:00Z")
        assert sensor.is_reading_safe(reading) is False

    def test_set_status(self):
        sensor = make_sensor()
        assert sensor.status == SensorStatus.ONLINE
        sensor.set_status(SensorStatus.OFFLINE)
        assert sensor.status == SensorStatus.OFFLINE

    def test_smoke_sensor_unsafe_above_threshold(self):
        sensor = make_sensor(SensorType.SMOKE)
        reading = sensor.record_reading(15.0, "%", "2024-01-01T00:00:00Z")
        assert sensor.is_reading_safe(reading) is False

    def test_smoke_sensor_safe_within_threshold(self):
        sensor = make_sensor(SensorType.SMOKE)
        reading = sensor.record_reading(5.0, "%", "2024-01-01T00:00:00Z")
        assert sensor.is_reading_safe(reading) is True
