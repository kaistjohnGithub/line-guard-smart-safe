-- Migration 002: Add direct camera management fields

ALTER TABLE cameras
    ADD COLUMN IF NOT EXISTS process_id INTEGER,
    ADD COLUMN IF NOT EXISTS sop_id     INTEGER,
    ADD COLUMN IF NOT EXISTS process   VARCHAR(150),
    ADD COLUMN IF NOT EXISTS station   VARCHAR(150),
    ADD COLUMN IF NOT EXISTS fps       INTEGER DEFAULT 15,
    ADD COLUMN IF NOT EXISTS video_src VARCHAR(500);

UPDATE cameras
SET
    process = COALESCE(process, zone, 'Unassigned'),
    station = COALESCE(station, location, name),
    fps = COALESCE(fps, CASE
        WHEN LOWER(COALESCE(status, 'online')) = 'offline' THEN 0
        WHEN LOWER(COALESCE(status, 'online')) IN ('warning', 'delay') THEN 3
        ELSE 15
    END)
WHERE process IS NULL OR station IS NULL OR fps IS NULL;

UPDATE cameras SET process = 'Assembly / Press', station = 'Station 01', fps = 15, video_src = './src/videos/sample_forklift_safety.mp4' WHERE id = 'CAM-A01';
UPDATE cameras SET process = 'Assembly / Press', station = 'Station 02', fps = 14, video_src = NULL WHERE id = 'CAM-A02';
UPDATE cameras SET process = 'Assembly / Sampling', station = 'Station 03', fps = 3, video_src = './src/videos/synthetic_factory.mp4' WHERE id = 'CAM-A03';
UPDATE cameras SET process = 'Assembly / Packing', station = 'Station 04', fps = 0, video_src = NULL, status = 'offline' WHERE id = 'CAM-A04';
UPDATE cameras SET process = 'Assembly B / Welding', station = 'Station 01', fps = 15, video_src = NULL WHERE id = 'CAM-A05';
UPDATE cameras SET process = 'Assembly B / QC', station = 'Station 02', fps = 15, video_src = NULL WHERE id = 'CAM-A06';
UPDATE cameras SET process = 'Assembly C / Robot', station = 'Station 01', fps = 15, video_src = NULL WHERE id = 'CAM-A07';
UPDATE cameras SET process = 'Assembly C / Conveyor', station = 'Station 02', fps = 12, video_src = NULL WHERE id = 'CAM-A08';
