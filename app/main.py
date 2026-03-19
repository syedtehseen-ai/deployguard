from fastapi import FastAPI
from app.database import get_connection
from app.schemas import DeploymentCreate
from app.routes.analyze import router

app = FastAPI(title="DeployGuard")


@app.get("/health")
def health_check():
    return {"status": "ok"}

app.include_router(router)


@app.get("/deployments")
def get_deployments():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM deployments")
    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    return {"deployments": rows}

@app.post("/deployments")
def create_deployment(deployment: DeploymentCreate):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "INSERT INTO deployments (name, status) VALUES (%s, %s)",
        (deployment.name, deployment.status)
    )

    conn.commit()

    cursor.close()
    conn.close()

    return {"message": "deployment stored"}