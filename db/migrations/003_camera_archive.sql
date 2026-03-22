-- Migration 003: Add camera archive support

ALTER TABLE cameras
    ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

UPDATE cameras
SET archived = COALESCE(archived, FALSE)
WHERE archived IS NULL;
