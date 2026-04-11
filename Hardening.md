# DeployGuard v0.1 — Workload Hardening

This phase focuses on **hardening Kubernetes workloads** to align with production-grade best practices.

---

## 🔐 Hardening Areas Implemented

### 1. Resource Limits

Defined CPU and memory requests/limits to prevent resource starvation:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

**Why?**

* Prevent noisy neighbor issues
* Ensure proper scheduling
* Avoid node instability

---

### 2. Security Context

Applied container-level security controls:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

**Key Learnings:**

* Containers must be built to support non-root execution
* File permissions must align with runtime user
* Read-only filesystem enforces immutability

---

### 3. Network Policies

Restricted database access to only authorized pods. 
**Note** - works only on supported cni

**Policy Goal:**

```text
Allow: deployguard → postgres
Block: all other pods
```

**Validation Test:**

```bash
kubectl run nwpolicy --rm -it --restart=Never --image=python -- \
python -c 'import socket; s=socket.socket(); s.settimeout(3); print("Connected" if not s.connect_ex(("postgres-service",5432)) else "Blocked")'
```

Result:

```text
Blocked
```

From DeployGuard pod:

```bash
kubectl exec -it <deployguard-pod> -- python -c 'import socket; s=socket.socket(); s.settimeout(3); print("Connected" if not s.connect_ex(("postgres-service",5432)) else "Blocked")'
```

Result:

```text
Connected
```

---

### 4. Pod Security (Restricted Mode)

Applied Kubernetes Pod Security Standards via namespace:

```bash
kubectl label ns deployguard pod-security.kubernetes.io/enforce=restricted
```

**Effect:**

* Prevents root containers
* Blocks privilege escalation
* Enforces secure defaults

---

### 5. Basic Observability

Used Kubernetes native commands for monitoring:

```bash
kubectl top pods
kubectl describe pod
kubectl logs
kubectl events
```

**Focus Areas:**

* Resource usage
* CrashLoopBackOff debugging
* OOMKilled detection

---

## 🧠 Key Takeaways

* SecurityContext must be supported by Docker image design
* Network policies depend on CNI support
* Pod Security enforces cluster-level security
* Resource limits are critical for multi-tenant clusters
* Observability is essential for debugging production issues

---

---

## 🚀 Next Phase

**Week 5–6 — Analyzer Engine**

The next milestone is to build the core DeployGuard feature:

* Analyze Kubernetes Deployment YAML
* Detect misconfigurations
* Generate risk scores
* Provide recommendations

---



#### IAM EKS 

Harden
Restrict API access:
Private endpoint only (later)
Use IAM roles properly
Avoid admin access everywhere



#### NAT 

(Advanced but powerful)

Instead of NAT dependency, you can add:

👉 VPC endpoints:

SSM
ECR
EC2

👉 Then nodes work without internet

Reduce NAT dependency:

Create endpoints for:

ECR (api + dkr)
S3
STS

Example:

aws ec2 create-vpc-endpoint \
  --vpc-id <vpc-id> \
  --service-name com.amazonaws.ap-south-1.ecr.api \
  --vpc-endpoint-type Interface



# HELM
## add customLabels through helper.tpl
  ## 🔥 Custom labels (optional)
{{- with .Values.customLabels }}
{{ toYaml . | indent 0 }}
{{- end }}