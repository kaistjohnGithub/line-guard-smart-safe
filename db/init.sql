-- Line Guard — initial schema

-- Cameras
CREATE TABLE IF NOT EXISTS cameras (
    id          VARCHAR(20) PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    process_id  INTEGER,
    sop_id      INTEGER,
    process     VARCHAR(150),
    station     VARCHAR(150),
    fps         INTEGER DEFAULT 15,
    video_src   VARCHAR(500),
    zone        VARCHAR(100),
    location    VARCHAR(200),
    status      VARCHAR(20) DEFAULT 'online',   -- online / offline / warning
    archived    BOOLEAN DEFAULT FALSE,
    archived_at TIMESTAMPTZ,
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

-- Analysis jobs (video → Qwen pipeline)
CREATE TABLE IF NOT EXISTS analysis_jobs (
    id          SERIAL PRIMARY KEY,
    camera_id   VARCHAR(20) REFERENCES cameras(id),
    video_path  VARCHAR(500) NOT NULL,
    status      VARCHAR(20) DEFAULT 'pending',   -- pending / running / done / failed
    model       VARCHAR(100) DEFAULT 'Qwen/Qwen2.5-VL-3B-Instruct',
    interval_sec NUMERIC(4,1) DEFAULT 3.0,
    total_frames INTEGER DEFAULT 0,
    processed_frames INTEGER DEFAULT 0,
    error_msg   TEXT,
    started_at  TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Frame analysis results (one row per frame)
CREATE TABLE IF NOT EXISTS frame_results (
    id          SERIAL PRIMARY KEY,
    job_id      INTEGER REFERENCES analysis_jobs(id) ON DELETE CASCADE,
    camera_id   VARCHAR(20) REFERENCES cameras(id),
    event_id    INTEGER REFERENCES events(id),
    frame_idx   INTEGER NOT NULL,
    timestamp_sec NUMERIC(8,2),
    timestamp_str VARCHAR(20),
    description TEXT,
    safety_status VARCHAR(20),   -- SAFE / WARNING / DANGER
    frame_path  VARCHAR(500),    -- path to saved frame image
    latency_ms  INTEGER,
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

-- Backfill direct camera fields for fresh installs and legacy rows
UPDATE cameras SET process = 'Assembly / Press', station = 'Station 01', fps = 15, video_src = './src/videos/sample_forklift_safety.mp4' WHERE id = 'CAM-A01';
UPDATE cameras SET process = 'Assembly / Press', station = 'Station 02', fps = 14, video_src = NULL WHERE id = 'CAM-A02';
UPDATE cameras SET process = 'Assembly / Sampling', station = 'Station 03', fps = 3, video_src = './src/videos/synthetic_factory.mp4' WHERE id = 'CAM-A03';
UPDATE cameras SET process = 'Assembly / Packing', station = 'Station 04', fps = 0, video_src = NULL, status = 'offline' WHERE id = 'CAM-A04';
UPDATE cameras SET process = 'Assembly B / Welding', station = 'Station 01', fps = 15, video_src = NULL WHERE id = 'CAM-A05';
UPDATE cameras SET process = 'Assembly B / QC', station = 'Station 02', fps = 15, video_src = NULL WHERE id = 'CAM-A06';
UPDATE cameras SET process = 'Assembly C / Robot', station = 'Station 01', fps = 15, video_src = NULL WHERE id = 'CAM-A07';
UPDATE cameras SET process = 'Assembly C / Conveyor', station = 'Station 02', fps = 12, video_src = NULL WHERE id = 'CAM-A08';
