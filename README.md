# LineGuard Smart Safe

A Python safety-monitoring system for smart factories. LineGuard continuously monitors worker positions, sensor readings, and production-line zones, raising alerts and logging incidents automatically whenever a hazard is detected.

## Features

| Feature | Description |
|---|---|
| **Safety zone monitoring** | Detect worker entry into restricted, danger, or emergency-exit zones and raise alerts immediately |
| **Multi-sensor support** | Evaluate readings from temperature, gas, smoke, proximity, vibration and motion sensors against configurable thresholds |
| **Automatic alerting** | Raise typed, prioritised alerts (INFO → WARNING → HIGH → CRITICAL) with full lifecycle management (acknowledge / resolve / escalate) |
| **Incident logging** | Log and track safety incidents with root-cause analysis and corrective actions |
| **Emergency mode** | Automatically activate system-wide emergency mode on fire or gas-leak detection |
| **Compliance reporting** | Generate period compliance reports with a scored summary |

## Architecture

```
src/
├── __init__.py
├── line_guard.py        # Top-level system coordinator (LineGuard class)
├── safety_zone.py       # Zone definitions, violation detection
├── sensor.py            # Sensor models and threshold evaluation
├── alert.py             # Alert management and notification handlers
└── incident_logger.py   # Incident tracking and compliance reports
tests/
├── test_safety_zone.py
├── test_sensor.py
├── test_alert.py
├── test_incident_logger.py
└── test_line_guard.py   # Integration tests
```

## Quick Start

```python
from src.line_guard import LineGuard
from src.safety_zone import SafetyZone, ZoneType, Point
from src.sensor import Sensor, SensorType

# 1. Create the system
system = LineGuard()

# 2. Register safety zones
system.add_zone(SafetyZone(
    zone_id="ROBOT-01",
    name="Robotic Arm Area",
    zone_type=ZoneType.DANGER,
    top_left=Point(0, 0),
    bottom_right=Point(5, 5),
))

# 3. Register sensors
system.add_sensor(Sensor(
    sensor_id="GAS-01",
    sensor_type=SensorType.GAS,
    zone_id="ROBOT-01",
    location_description="Near welding station",
))

# 4. Report worker position – violations raise alerts automatically
violations = system.report_worker_position("W001", x=2.5, y=2.5)

# 5. Process sensor readings – threshold breaches raise alerts automatically
alert = system.process_sensor_reading("GAS-01", value=50.0, unit="ppm")

# 6. Check overall safety state
print(system.safety_status())
# {'emergency_mode': True, 'active_alerts': 2, 'critical_alerts': 1, ...}

# 7. Generate a compliance report
report = system.generate_compliance_report("2024-01-01", "2024-01-31")
print(f"Compliant: {report.is_compliant}  Score: {report.compliance_score:.1f}%")
```

## Safety Zones

| Zone type | Violation severity | Auto-incident logged |
|---|---|---|
| `SAFE` | – (no violation) | No |
| `RESTRICTED` | MEDIUM | Yes |
| `DANGER` | HIGH | Yes |
| `EMERGENCY_EXIT` | CRITICAL | No |

## Sensor Thresholds

| Sensor type | Safe range | Unit |
|---|---|---|
| `TEMPERATURE` | 0 – 60 | °C |
| `GAS` | 0 – 25 | ppm |
| `PROXIMITY` | ≥ 0.5 | m |
| `VIBRATION` | 0 – 5 | m/s² |
| `SMOKE` | 0 – 10 | % optical density |
| `MOTION` | 0 – 1 | binary |

## Running Tests

```bash
pip install pytest
python -m pytest tests/ -v
```