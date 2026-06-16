import time
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pathlib import Path

from routers import cron, cidr, dockerfile_router
from services.db_service import get_tool_stats

app = FastAPI(title="DevOps Toolbox")
APP_START_TIME = time.time()

# Mount static files
static_dir = Path(__file__).parent / "static"
static_dir.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

# Templates
templates_dir = Path(__file__).parent / "templates"
templates_dir.mkdir(parents=True, exist_ok=True)
templates = Jinja2Templates(directory=str(templates_dir))

# Include routers
app.include_router(cron.router)
app.include_router(cidr.router)
app.include_router(dockerfile_router.router)

@app.get("/health")
async def health():
    """Liveness probe: verifies the Python process is alive."""
    return {"status": "alive", "service": "devops-toolbox"}


@app.get("/ready")
async def readiness():
    """Readiness probe: verifies application is initialized and routes are loaded."""
    uptime = time.time() - APP_START_TIME
    checks = {
        "routers_loaded": len(app.routes) > 5,
        "uptime_seconds": round(uptime, 2),
    }
    
    if not checks["routers_loaded"]:
        raise HTTPException(status_code=503, detail=checks)
        
    return {"status": "ready", **checks}


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    stats = get_tool_stats()
    
    return templates.TemplateResponse(request, "index.html", {
        "request": request, 
        "stats": stats
    })
