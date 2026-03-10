# DeployGuard v0.1 Milestone

**Stateful backend with PostgreSQL integration and deployment registration API**

This milestone completes the **DeployGuard v0.1 backend**, turning the system from a simple FastAPI service into a **stateful Kubernetes application** backed by PostgreSQL.

---

# Image Versions

| Version  | Feature                      |
| -------- | ---------------------------- |
| **v0.1** | Basic FastAPI service        |
| **v0.2** | PostgreSQL integration       |
| **v0.3** | POST `/deployments` endpoint |

---

# Endpoints

### Health Check

```http
GET /health
```

Example response

```json
{
 "status": "ok"
}
```

---

### Get Deployments

```http
GET /deployments
```

Example response

```json
{
 "deployments":[
  [1,"deploy-test","healthy","2026-03-10T10:10:33.260323"],
  [2,"payment-service","healthy","2026-03-10T10:27:46.089774"]
 ]
}
```

---

### Register Deployment

```http
POST /deployments
```

Example request

```json
{
 "name": "payment-service",
 "status": "healthy"
}
```

Example response

```json
{
 "message": "deployment stored"
}
```

---

# PostgreSQL Setup

Connected to PostgreSQL pod:

```bash
kubectl exec -it postgres-5f7997f9b8-lpctk -- psql -U postgres
```

Create application user:

```sql
CREATE USER deployguard WITH PASSWORD 'strongpassword';
```

Create database:

```sql
CREATE DATABASE deployguard;
```

Grant privileges:

```sql
GRANT ALL PRIVILEGES ON DATABASE deployguard TO deployguard;
```

Switch database:

```sql
\c deployguard
```

Create table:

```sql
CREATE TABLE deployments (
 id SERIAL PRIMARY KEY,
 name TEXT NOT NULL,
 status TEXT,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Grant table permissions:

```sql
GRANT ALL PRIVILEGES ON TABLE deployments TO deployguard;
```

Grant sequence permissions:

```sql
GRANT USAGE, SELECT ON SEQUENCE deployments_id_seq TO deployguard;
```

---

# Kubernetes Configuration

Database configuration injected using **ConfigMap and Secret**.

Example environment variables:

```yaml
env:
- name: DB_HOST
  value: postgres-service
- name: DB_NAME
  value: deployguard
envFrom:
- secretRef:
    name: deployguard-secret
```

Secret contains:

```text
DB_USERNAME
DB_PASSWORD
```

---

# Challenges Faced and Fixes

### 1. PostgreSQL user did not exist

Error

```text
psql: FATAL: role "deployguard" does not exist
```

Fix

```sql
CREATE USER deployguard WITH PASSWORD 'strongpassword';
```

---

### 2. Table permission error

Error

```text
psycopg2.errors.InsufficientPrivilege: permission denied for table deployments
```

Fix

```sql
GRANT ALL PRIVILEGES ON TABLE deployments TO deployguard;
```

---

### 3. Sequence permission error

Error

```text
psycopg2.errors.InsufficientPrivilege: permission denied for sequence deployments_id_seq
```

Fix

```sql
GRANT USAGE, SELECT ON SEQUENCE deployments_id_seq TO deployguard;
```

---

### 4. NodePort not accessible in kind

Since the cluster runs inside Docker, NodePort cannot be accessed directly from localhost.

Solution used:

```bash
kubectl port-forward svc/deployguard-service 8000:8000
```

Access application via

```
http://localhost:8000
```

---

# Kubernetes Networking Flow

```text
FastAPI Pod
     │
CoreDNS resolves postgres-service
     │
Service ClusterIP
     │
kube-proxy iptables routing
     │
PostgreSQL Pod
```

---

# Storage Architecture

```text
Postgres Container
       │
Volume Mount
       │
PersistentVolumeClaim
       │
PersistentVolume
       │
Node Storage (local-path provisioner)
```

PVC configuration:

```yaml
accessModes:
- ReadWriteOnce
```

This allows mounting by **one node at a time**.

---

# Learning Outcomes

Key Kubernetes concepts explored:

```text
Service discovery using CoreDNS
kube-proxy traffic routing
Persistent storage using PVC
ConfigMap vs Secret
Readiness and liveness probes
Database permission model
```

---

# DeployGuard Mission Progress

Current status:

```text
DeployGuard Mission
Version: v0.1
Week 2 completed
```

Completed:

```text
FastAPI backend
Docker image
Kubernetes deployment
Service networking
ConfigMap and Secret
PostgreSQL database
PersistentVolumeClaim
FastAPI ↔ PostgreSQL integration
Deployment registration API
```

---

# Next Phase

Upcoming milestone:

```text
Week 3
CI/CD automation
```

Planned features:

```text
GitHub Actions pipeline
Automatic Docker build
Push image to DockerHub
Automated Kubernetes deployment
```


