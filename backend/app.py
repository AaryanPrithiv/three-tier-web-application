from flask import Flask, jsonify, request
import os
import psycopg2


app = Flask(__name__)


def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("POSTGRES_HOST", "localhost"),
        port=os.getenv("POSTGRES_PORT", "5432"),
        dbname=os.getenv("POSTGRES_DB", "appdb"),
        user=os.getenv("POSTGRES_USER", "appuser"),
        password=os.getenv("POSTGRES_PASSWORD", "appsecret"),
    )


def init_db():
    conn = get_db_connection()
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS visits (
                        id SERIAL PRIMARY KEY,
                        created_at TIMESTAMP DEFAULT NOW()
                    )
                    """
                )
    finally:
        conn.close()


@app.get("/api/healthz")
def healthz():
    try:
        conn = get_db_connection()
        conn.close()
        db_state = "ok"
    except Exception:
        db_state = "unavailable"

    return jsonify({"status": "ok", "database": db_state})


@app.get("/api/status")
def status():
    conn = get_db_connection()
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("SELECT COUNT(*) FROM visits")
                visits = cur.fetchone()[0]
    finally:
        conn.close()

    return jsonify({
        "app": "three-tier-web-application",
        "database": "postgres",
        "visits": visits,
    })


@app.post("/api/visit")
def visit():
    conn = get_db_connection()
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO visits DEFAULT VALUES RETURNING id")
                visit_id = cur.fetchone()[0]
    finally:
        conn.close()

    return jsonify({"message": "visit recorded", "id": visit_id})


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
