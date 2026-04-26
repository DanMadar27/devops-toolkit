CREATE TABLE events (
  id           BIGSERIAL PRIMARY KEY,
  workflow_id  BIGINT NOT NULL,
  event_name   TEXT NOT NULL,
  status       TEXT CHECK (status IN ('PENDING', 'PROCESSING', 'PROCESSED', 'FAILED', 'CANCELED')) NOT NULL DEFAULT 'PENDING',
  description  TEXT,
  created_at   TIMESTAMP DEFAULT NOW(),
  updated_at   TIMESTAMP
);

CREATE INDEX idx_events_workflow_id ON events(workflow_id);
CREATE INDEX idx_events_status ON events(status);
