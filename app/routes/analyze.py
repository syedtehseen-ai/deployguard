from fastapi import APIRouter, Request, Body
from app.analyzer.engine import analyze_yaml

router = APIRouter()


@router.post("/analyze")
async def analyze(body: str = Body(...)):
    yaml_input = body.decode("utf-8")

    result = analyze_yaml(yaml_input)

    return result