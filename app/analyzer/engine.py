import yaml
from app.analyzer.rules import run_all_checks

def analyze_yaml(yaml_input: str):
    # Check empty input
    if not yaml_input or not yaml_input.strip():
        return {
            "risk": "HIGH",
            "issues": ["Empty input"],
            "suggestions": ["Provide Kubernetes Deployment YAML"]
        }

    # Parse safely
    try:
        parsed = yaml.safe_load(yaml_input)
    except Exception as e:
        return {
            "risk": "HIGH",
            "issues": [f"Invalid YAML: {str(e)}"],
            "suggestions": ["Fix YAML syntax"]
        }

    # Check parsed result
    if not parsed:
        return {
            "risk": "HIGH",
            "issues": ["Invalid or empty YAML"],
            "suggestions": ["Provide valid Deployment YAML"]
        }

    issues = run_all_checks(parsed)
    if len(issues) == 0:
        risk = "LOW"
    elif len(issues) <= 2:
        risk = "MEDIUM"
    else:
        risk = "HIGH"

    return {
        "risk": risk,
        "issues": issues,
        "suggestions": [f"Fix: {issue}" for issue in issues]
    }