CREATE TABLE IF NOT EXISTS items (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('Task', 'Incident')),
    status VARCHAR(50) NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'Resolved')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS items_created_at_idx ON items (created_at DESC);

CREATE ROLE taskpulse_app LOGIN;
GRANT CONNECT ON DATABASE taskpulse TO taskpulse_app;
GRANT USAGE ON SCHEMA public TO taskpulse_app;
GRANT SELECT ON TABLE items TO taskpulse_app;
GRANT INSERT (title, type, status) ON TABLE items TO taskpulse_app;
GRANT UPDATE (status) ON TABLE items TO taskpulse_app;
GRANT USAGE, SELECT ON SEQUENCE items_id_seq TO taskpulse_app;
