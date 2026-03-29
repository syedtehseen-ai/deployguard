WEIGHTS = {
    "Container uses latest tag": 2,
    "Missing resource limits/requests": 3,
    "Container may run as root": 5,
    "Missing liveness/readiness probes": 4,
    "Missing labels in metadata": 2,
    "Selector does not match pod labels": 5,
    "No containers found": 5,
    "Invalid Deployment structure": 5,
}

def calculate_risk(issues):
    score = sum(WEIGHTS.get(issue, 1) for issue in issues)

    if score <= 3:
        return "LOW", score
    elif score <= 7:
        return "MEDIUM", score
    else:
        return "HIGH", score