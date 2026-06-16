from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.cidr_service import calculate_cidr
from services.cache_service import get_cache, set_cache
from services.db_service import log_tool_usage

router = APIRouter(prefix="/tools", tags=["cidr"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

@router.get("/cidr", response_class=HTMLResponse)
async def get_cidr(request: Request):
    return templates.TemplateResponse(request, "cidr.html", {"request": request})

@router.post("/cidr", response_class=HTMLResponse)
async def post_cidr(request: Request, cidr: str = Form(...)):
    cache_key = cidr.strip()
    cache_hit = False
    
    # Log execution in audit database
    log_tool_usage("cidr", cache_key)
    
    # Retrieve from cache
    result = get_cache(cache_key)
    if result:
        cache_hit = True
    else:
        result = calculate_cidr(cache_key)
        if result.get("success"):
            set_cache(cache_key, result)

    return templates.TemplateResponse(
        request, 
        "cidr.html", 
        {"request": request, "result": result, "cidr": cidr, "cache_hit": cache_hit}
    )


