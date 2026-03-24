from fastapi import APIRouter, Request
from app.analyzer.engine import analyze_yaml

router = APIRouter()

@router.post("/analyze")
async def analyze(request: Request):
    body = await request.body()
    yaml_input = body.decode("utf-8")

    result = analyze_yaml(yaml_input)
    return result