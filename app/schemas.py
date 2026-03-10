from pydantic import BaseModel

class DeploymentCreate(BaseModel):
    name: str
    status: str