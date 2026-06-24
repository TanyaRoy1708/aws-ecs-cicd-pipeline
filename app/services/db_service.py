import os
import logging
from sqlalchemy import create_engine, text

logger = logging.getLogger(__name__)

DB_HOST = os.getenv("DB_HOST", "")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "devopstoolbox")
DB_PORT = os.getenv("DB_PORT", "5432")

db_engine = None
_local_stats_count = {"cron": 0, "cidr": 0, "dockerfile": 0}

if DB_HOST and DB_PASSWORD:
    db_url = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    try:
        db_engine = create_engine(db_url, pool_pre_ping=True, connect_args={"connect_timeout": 3})
        # Auto-create audit logs table if it doesn't exist
        with db_engine.begin() as conn:
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS tool_audit_logs (
                    id SERIAL PRIMARY KEY,
                    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                    tool_name VARCHAR(50) NOT NULL,
                    input_value TEXT
                )
            """))
    except Exception as e:
        logger.error("Failed to connect to database at startup: %s", e)
        db_engine = None

def log_tool_usage(tool_name: str, input_value: str):
    if db_engine:
        try:
            with db_engine.begin() as conn:
                conn.execute(
                    text("INSERT INTO tool_audit_logs (tool_name, input_value) VALUES (:tool, :val)"),
                    {"tool": tool_name, "val": input_value[:100]}
                )
            return
        except Exception as e:
            logger.warning("Failed to log tool usage to DB, falling back to memory: %s", e)
            pass
    # Fallback to local memory stats
    if tool_name in _local_stats_count:
        _local_stats_count[tool_name] += 1

def get_tool_stats() -> dict:
    stats = {"cron": 0, "cidr": 0, "dockerfile": 0}
    if db_engine:
        try:
            with db_engine.connect() as conn:
                for tool in stats.keys():
                    res = conn.execute(
                        text("SELECT COUNT(*) FROM tool_audit_logs WHERE tool_name = :tool"),
                        {"tool": tool}
                    )
                    stats[tool] = res.scalar() or 0
            return stats
        except Exception as e:
            logger.warning("Failed to fetch tool stats from DB, falling back to memory: %s", e)
            pass
    return _local_stats_count
