-- Line Guard — initial schema

-- Cameras
CREATE TABLE IF NOT EXISTS cameras (
    id          VARCHAR(20) PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    zone        VARCHAR(100),
    location    VARCHAR(200),
    status      VARCHAR(20) DEFAULT 'online',   -- online / offline / warning
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Safety rules
CREATE TABLE IF NOT EXISTS safety_rules (
    id          SERIAL PRIMARY KEY,
    category    VARCHAR(50) NOT NULL,            -- action / condition / nearmiss
    description TEXT NOT NULL,
    severity    VARCHAR(20) DEFAULT 'medium',    -- critical / high / medium / low
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Standard Operating Procedures
CREATE TABLE IF NOT EXISTS sops (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(30) NOT NULL UNIQUE,
    title       VARCHAR(200) NOT NULL,
    category    VARCHAR(50),
    status      VARCHAR(20) DEFAULT 'active',
    version     VARCHAR(10) DEFAULT '1.0',
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sop_steps (
    id          SERIAL PRIMARY KEY,
    sop_id      INTEGER REFERENCES sops(id) ON DELETE CASCADE,
    step_no     INTEGER NOT NULL,
    description TEXT NOT NULL
);

-- VLM Prompts
CREATE TABLE IF NOT EXISTS prompts (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    category    VARCHAR(50),
    content     TEXT NOT NULL,
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Events (AI detection results)
CREATE TABLE IF NOT EXISTS events (
    id          SERIAL PRIMARY KEY,
    camera_id   VARCHAR(20) REFERENCES cameras(id),
    event_type  VARCHAR(50) NOT NULL,            -- PPE_VIOLATION / NEAR_MISS / SOP_VIOLATION etc.
    severity    VARCHAR(20) DEFAULT 'medium',
    description TEXT,
    confidence  NUMERIC(5,2),
    metadata    JSONB,
    occurred_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alerts
CREATE TABLE IF NOT EXISTS alerts (
    id          SERIAL PRIMARY KEY,
    event_id    INTEGER REFERENCES events(id),
    camera_id   VARCHAR(20) REFERENCES cameras(id),
    title       VARCHAR(200) NOT NULL,
    severity    VARCHAR(20) DEFAULT 'medium',
    status      VARCHAR(20) DEFAULT 'open',      -- open / acknowledged / resolved
    acknowledged_at TIMESTAMPTZ,
    resolved_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Media files (images & videos from AI analysis)
CREATE TABLE IF NOT EXISTS media_files (
    id          SERIAL PRIMARY KEY,
    event_id    INTEGER REFERENCES events(id),
    camera_id   VARCHAR(20) REFERENCES cameras(id),
    file_type   VARCHAR(10) NOT NULL,            -- image / video
    filename    VARCHAR(300) NOT NULL,
    filepath    VARCHAR(500) NOT NULL,           -- relative to MEDIA_ROOT
    size_bytes  BIGINT,
    mime_type   VARCHAR(80),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_events_camera   ON events(camera_id);
CREATE INDEX IF NOT EXISTS idx_events_occurred ON events(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_status   ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON alerts(severity);
CREATE INDEX IF NOT EXISTS idx_media_event     ON media_files(event_id);

-- Seed cameras
INSERT INTO cameras (id, name, zone, location, status) VALUES
  ('CAM-A01','Assembly Line A — Station 1','Zone A','Building 1, Floor 1','online'),
  ('CAM-A02','Assembly Line A — Station 2','Zone A','Building 1, Floor 1','online'),
  ('CAM-A03','Welding Bay B','Zone B','Building 2, Floor 1','warning'),
  ('CAM-A04','Forklift Corridor C','Zone C','Building 1, Corridor','online'),
  ('CAM-A05','Quality Control D','Zone D','Building 3, Floor 1','online'),
  ('CAM-A06','Loading Dock E','Zone E','Building 1, Loading Area','online'),
  ('CAM-A07','Maintenance Area F','Zone F','Building 4, Floor 1','offline'),
  ('CAM-A08','Emergency Exit G','Zone G','Building 1, Exit','online')
ON CONFLICT (id) DO NOTHING;
