"""Run the versioned SQL migrations once before deploying the API."""
import os
from pathlib import Path

import psycopg2

from app import database_config


def main():
    migration_dir = Path(__file__).parent / "migrations"
    with psycopg2.connect(**database_config()) as conn, conn.cursor() as cur:
        cur.execute(
            "CREATE TABLE IF NOT EXISTS schema_migrations "
            "(version VARCHAR(255) PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP)"
        )
        for migration in sorted(migration_dir.glob("*.sql")):
            cur.execute("SELECT 1 FROM schema_migrations WHERE version = %s", (migration.name,))
            if cur.fetchone():
                continue
            cur.execute(migration.read_text(encoding="utf-8"))
            cur.execute("INSERT INTO schema_migrations (version) VALUES (%s)", (migration.name,))
            print(f"Applied {migration.name}", flush=True)
        if os.getenv("DB_ENABLE_RDS_IAM_ROLE") == "true":
            cur.execute("GRANT rds_iam TO taskpulse_app")


if __name__ == "__main__":
    main()
