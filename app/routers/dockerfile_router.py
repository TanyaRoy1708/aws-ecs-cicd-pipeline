from fastapi import APIRouter, Request, Form, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.dockerfile_service import lint_dockerfile
from services.db_service import log_tool_usage

router = APIRouter(prefix="/tools", tags=["dockerfile"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

MAX_DOCKERFILE_SIZE = 100_000  # 100 KB

@router.get("/dockerfile", response_class=HTMLResponse)
async def get_dockerfile(request: Request):
    return templates.TemplateResponse(request, "dockerfile.html", {"request": request})

@router.post("/dockerfile", response_class=HTMLResponse)
async def post_dockerfile(request: Request, dockerfile: str = Form(...)):
    if len(dockerfile) > MAX_DOCKERFILE_SIZE:
        raise HTTPException(status_code=413, detail="Dockerfile input exceeds the 100KB size limit.")
    log_tool_usage("dockerfile", dockerfile)
    result = lint_dockerfile(dockerfile)
    return templates.TemplateResponse(request, "dockerfile.html", {"request": request, "result": result, "dockerfile": dockerfile})

