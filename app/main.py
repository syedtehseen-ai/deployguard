from fastapi import FastAPI

app = FastAPI(title="DeployGuard")

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/deployments")
def get_deployments():
    return {
        "deployments": [
            {"name": "sample-app", "status": "Running"},
            {"name": "worker", "status": "Pending"}
        ]
    }