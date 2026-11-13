import os
from contextlib import contextmanager
from functools import lru_cache

import boto3
import psycopg2
from flask import Flask, jsonify, request
from psycopg2.extras import RealDictCursor

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 16 * 1024

ITEM_TYPES = {"Task", "Incident"}
ITEM_STATUSES = {"Open", "Resolved"}


@lru_cache(maxsize=4)
def rds_client(region):
    return boto3.client("rds", region_name=region)


def database_config():
    required = ("DB_HOST", "DB_NAME", "DB_USER")
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise RuntimeError(f"Missing required database settings: {', '.join(missing)}")
    config = {
        "host": os.environ["DB_HOST"],
        "dbname": os.environ["DB_NAME"],
        "user": os.environ["DB_USER"],
        "sslmode": os.getenv("DB_SSLMODE", "verify-full"),
        "connect_timeout": 5,
        "application_name": "taskpulse-api",
    }
    if config["sslmode"] in {"verify-ca", "verify-full"}:
        config["sslrootcert"] = os.getenv(
            "DB_SSLROOTCERT", "/etc/ssl/certs/rds-global-bundle.pem"
        )
    auth_mode = os.getenv("DB_AUTH_MODE", "password")
    if auth_mode == "iam":
        region = os.getenv("AWS_REGION")
        if not region:
            raise RuntimeError("AWS_REGION is required when DB_AUTH_MODE=iam")
        config["password"] = rds_client(region).generate_db_auth_token(
            DBHostname=config["host"],
            Port=5432,
            DBUsername=config["user"],
            Region=region,
        )
    elif auth_mode == "password":
        password = os.getenv("DB_PASSWORD")
        if not password:
            raise RuntimeError("DB_PASSWORD is required when DB_AUTH_MODE=password")
        config["password"] = password
    else:
        raise RuntimeError("DB_AUTH_MODE must be password or iam")
    return config


@contextmanager
def get_db_connection():
    conn = psycopg2.connect(**database_config())
    try:
        with conn:
            yield conn
    finally:
        conn.close()


@app.get("/livez")
def livez():
    return jsonify(status="ok")


@app.get("/readyz")
@app.get("/health")
def readyz():
    try:
        with get_db_connection() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1")
    except (psycopg2.Error, RuntimeError):
        app.logger.exception("Readiness check failed")
        return jsonify(error="service unavailable"), 503
    return jsonify(status="ok")


@app.get("/api/items")
def get_items():
    with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("SELECT id, title, type, status, created_at FROM items ORDER BY created_at DESC;")
        return jsonify(cur.fetchall())


@app.post("/api/items")
def create_item():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify(error="request body must be a JSON object"), 400

    title = data.get("title")
    item_type = data.get("type")
    status = data.get("status", "Open")
    if not isinstance(title, str) or not title.strip() or len(title.strip()) > 255:
        return jsonify(error="title must be 1 to 255 characters"), 400
    if not isinstance(item_type, str) or item_type not in ITEM_TYPES:
        return jsonify(error="type must be Task or Incident"), 400
    if not isinstance(status, str) or status not in ITEM_STATUSES:
        return jsonify(error="status must be Open or Resolved"), 400

    with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            "INSERT INTO items (title, type, status) VALUES (%s, %s, %s) "
            "RETURNING id, title, type, status, created_at;",
            (title.strip(), item_type, status),
        )
        return jsonify(cur.fetchone()), 201


@app.put("/api/items/<int:item_id>/status")
def update_status(item_id):
    data = request.get_json(silent=True)
    if (
        not isinstance(data, dict)
        or not isinstance(data.get("status"), str)
        or data["status"] not in ITEM_STATUSES
    ):
        return jsonify(error="status must be Open or Resolved"), 400

    with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            "UPDATE items SET status = %s WHERE id = %s "
            "RETURNING id, title, type, status, created_at;",
            (data["status"], item_id),
        )
        item = cur.fetchone()
    if item is None:
        return jsonify(error="item not found"), 404
    return jsonify(item)


@app.errorhandler(psycopg2.Error)
def handle_database_error(error):
    app.logger.exception("Database request failed")
    return jsonify(error="service unavailable"), 503


@app.errorhandler(413)
def handle_large_request(_error):
    return jsonify(error="request body is too large"), 413
