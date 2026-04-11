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


---------------------------
---------------------------
# Ingress, service selector and Network policies

1. Wrong Ingress Backend Port → 503 Error
The Ingress resource was initially configured with an incorrect backend service port. As a result, requests reached the Ingress controller but failed to reach the application service, returning a 503 Service Unavailable error. Correcting the backend port to match the service port resolved the issue.

2. Service Selector Mismatch → No Endpoints
The Kubernetes Service selector did not match the labels of the target pods. Because of this mismatch, the service had no endpoints, and traffic could not reach the application pods. Updating the service selector to match the pod labels allowed the endpoints to be created and traffic to flow correctly.

3. NetworkPolicy Not Enforced Due to Unsupported CNI
A NetworkPolicy was created to restrict database access so that only the DeployGuard application could connect to PostgreSQL. However, the policy was not enforced because the cluster was using a CNI plugin that did not support NetworkPolicy enforcement. After identifying this limitation, the issue was understood and documented as a cluster networking constraint.

# HELM Phase

helm create deployguard