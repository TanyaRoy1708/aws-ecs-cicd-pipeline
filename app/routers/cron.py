from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.cron_service import explain_cron
from services.cache_service import get_cache, set_cache
from services.db_service import log_tool_usage

router = APIRouter(prefix="/tools", tags=["cron"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

@router.get("/cron", response_class=HTMLResponse)
async def get_cron(request: Request):
    return templates.TemplateResponse(request, "cron.html", {"request": request})

@router.post("/cron", response_class=HTMLResponse)
async def post_cron(request: Request, expression: str = Form(...)):
    cache_key = expression.strip()
    cache_hit = False
    
    # Log execution in audit database
    log_tool_usage("cron", cache_key)
    
    # Retrieve from cache
    result = get_cache(cache_key)
    if result:
        cache_hit = True
    else:
        result = explain_cron(cache_key)
        if result.get("success"):
            set_cache(cache_key, result)

    return templates.TemplateResponse(
        request, 
        "cron.html", 
        {"request": request, "result": result, "expression": expression, "cache_hit": cache_hit}
    )
