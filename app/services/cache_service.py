import os
import json
import redis

REDIS_HOST = os.getenv("REDIS_HOST", "")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

_local_fallback_cache = {}
redis_client = None

if REDIS_HOST:
    try:
        redis_client = redis.Redis(
            host=REDIS_HOST, 
            port=REDIS_PORT, 
            db=0, 
            decode_responses=True, 
            socket_connect_timeout=2
        )
        redis_client.ping()
    except Exception:
        redis_client = None

def get_cache(key: str) -> dict | None:
    if redis_client:
        try:
            val = redis_client.get(key)
            return json.loads(val) if val else None
        except Exception:
            pass
    return _local_fallback_cache.get(key)

def set_cache(key: str, value: dict, expire_seconds: int = 86400):
    if redis_client:
        try:
            redis_client.setex(key, expire_seconds, json.dumps(value))
            return
        except Exception:
            pass
    if len(_local_fallback_cache) >= 100:
        _local_fallback_cache.pop(next(iter(_local_fallback_cache)))
    _local_fallback_cache[key] = value
