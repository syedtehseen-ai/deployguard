------ MVP ---
normalize score (0–10 or 0–100)


------DONE----- Implement analyzer engine with v0.2 OF  PHASE 1 improvement and Hardening ----

list(yaml.safe_load_all(yaml_input)) 
[
  {Service...},
  {Deployment...}
]
-- Break testing ---
1. --data-binary @k8s/service.yaml
2. Remove containers
3. Send random text
-- Hardening ---
1. Risk scoring improvement
WEIGHTS = {
    "Container uses latest tag": 2,
    "Missing resource limits/requests": 3,
    "Container may run as root": 5,
    "Missing liveness/readiness probes": 4,
    "Selector does not match pod labels": 5,
}

def calculate_risk(issues):
    score = sum(WEIGHTS.get(i, 1) for i in issues)

    if score <= 3:
        return "LOW"
    elif score <= 7:
        return "MEDIUM"
    else:
        return "HIGH"
2. Implement multi document
---------------------------------------------------------------------