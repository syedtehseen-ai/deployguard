import yaml
from app.analyzer.rules import run_all_checks
from app.analyzer.scoring import calculate_risk

def analyze_yaml(yaml_input: str):

    if not yaml_input or not yaml_input.strip():
        return {
            "risk": "HIGH",
            "score": 10,
            "issues": ["Empty input"],
            "suggestions": ["Provide Kubernetes Deployment YAML"]
        }

    try:
        documents = list(yaml.safe_load_all(yaml_input))
    except Exception as e:
        return {
            "risk": "HIGH",
            "score": 10,
            "issues": [f"Invalid YAML: {str(e)}"],
            "suggestions": ["Fix YAML syntax"]
        }

    if not documents:
        return {
            "risk": "HIGH",
            "score": 10,
            "issues": ["Empty YAML documents"],
            "suggestions": ["Provide valid Kubernetes YAML"]
        }

    all_issues = []
    deployment_found = False

    for doc in documents:
        if not isinstance(doc, dict):
            continue

        if doc.get("kind") != "Deployment":
            continue

        deployment_found = True

        issues = run_all_checks(doc)
        all_issues.extend(issues)

    if not deployment_found:
        return {
            "risk": "LOW",
            "score": 0,
            "issues": ["No Deployment found in YAML"],
            "suggestions": ["Provide Deployment YAML for analysis"]
        }

    # remove duplicates
    all_issues = list(set(all_issues))

    risk, score = calculate_risk(all_issues)

    return {
        "engine_version": "v0.2",
        "risk": risk,
        "score": score,
        "issues": all_issues,
        "suggestions": [f"Fix: {issue}" for issue in all_issues]
    }