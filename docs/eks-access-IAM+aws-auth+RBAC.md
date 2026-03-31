
---

# 🔐 Understanding EKS Access – What I Broke and What I Fixed

While working on my EKS setup, I wanted to *really understand* how access control works.
Instead of just reading documentation, I intentionally broke things and observed the behavior.

This hands-on approach helped me understand EKS access in a much deeper and practical way.

> **Note**
> EKS access is primarily based on **IAM + `aws-auth` ConfigMap + RBAC**.
> Other authentication methods (certificates, OIDC, tokens) exist, but **authorization is always controlled by RBAC** and similar policies.

---
# 🧠 Core Idea
Access to an EKS cluster is controlled by multiple layers:
```text
kubeconfig → IAM → aws-auth → RBAC
```

Each layer has a clear responsibility:

| Layer          | Responsibility                     |
| -------------- | ---------------------------------- |
| **kubeconfig** | Where the cluster is               |
| **IAM**        | Who you are                        |
| **aws-auth**   | Whether you can enter the cluster  |
| **RBAC**       | What you can do inside the cluster |

---

# ❌ Scenario 1 — No IAM Permission

### Command

```bash
aws eks update-kubeconfig --region ap-south-1 --name deployguard-cluster-dev
```

### Error

```bash
AccessDeniedException: not authorized to perform eks:DescribeCluster
```

### Why This Happened

`update-kubeconfig` internally calls AWS API:

```text
eks:DescribeCluster
```

Without this permission, kubeconfig cannot be generated.

### ✅ Fix

```json
"Action": "eks:DescribeCluster"
```

---

# ❌ Scenario 2 — Permission Boundary Deny

Even after giving full permissions (`eks:*`), I applied a permission boundary:

```json
"Deny": "eks:DescribeCluster"
```

### Result

```text
explicit deny in a permissions boundary
```

### 🧠 Learning

* Permission boundaries **override IAM allow**
* They affect **AWS API calls only**
* They do **not affect Kubernetes API calls**

---

# ❌ Scenario 3 — IAM OK but aws-auth Missing

IAM worked and kubeconfig was created successfully.

### Command

```bash
kubectl get nodes
```

### Error

```text
You must be logged in to the server (Unauthorized)
```

### Why This Happened

* IAM authentication succeeded ✅
* Kubernetes **did not recognize the IAM role** ❌

---

### ✅ Fix — Add Role to `aws-auth`

```yaml
- rolearn: arn:aws:iam::1234567890:role/eks-test-role
  username: eks-test-role
  groups:
    - system:masters
```

### Result

```bash
kubectl get nodes
```

✅ Worked successfully

---

# ⚠️ Problem with `system:masters`

At this point everything worked, but:

* Full admin access ⚠️
* Not safe for production

---

# ❌ Scenario 4 — Remove Admin Access

Removed `system:masters` and implemented proper RBAC.

---

# ✅ Fix — Implement RBAC

## Step 1 — Create ClusterRole

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-read-only
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

---

## Step 2 — Bind Role to Group

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pod-read-only-binding
subjects:
- kind: Group
  name: dev-read-only
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-read-only
  apiGroup: rbac.authorization.k8s.io
```

---

## Step 3 — Update `aws-auth`

```yaml
- rolearn: arn:aws:iam::1234567890:role/eks-test-role
  username: eks-test-role
  groups:
    - dev-read-only
```

---

# ✅ Final Result

### Allowed

```bash
kubectl get pods
```

Output:

```text
nginx   Running
```

---

### Denied

```bash
kubectl get nodes
```

Error:

```text
nodes is forbidden
```

---

# 🧠 Key Learnings

* IAM controls **AWS API access**
* `aws-auth` maps **IAM identity → Kubernetes**
* RBAC controls **permissions inside cluster**
* Permission boundaries affect **only AWS APIs**
* `kubectl` talks to **Kubernetes API**, not AWS APIs

---

# 🔥 End-to-End Flow

```text
kubectl
   ↓
kubeconfig
   ↓
aws eks get-token
   ↓
IAM (authentication)
   ↓
aws-auth (mapping)
   ↓
RBAC (authorization)
   ↓
Kubernetes API
```

---

# 🚀 Final Takeaway

Understanding EKS access is not about memorizing commands.

It’s about understanding:

> **Where things break and why**

Breaking each layer helped me:

* Debug faster
* Design secure access
* Think like an architect

---

# 💡 Best Practice

❌ Avoid:

```text
system:masters
```

✅ Use:

```text
IAM Role → aws-auth → Custom Group → RBAC
```

---

# 🎯 Final Thought

This exercise helped me move from:

```text
"kubectl works"
```

to:

```text
"I understand why it works (or fails)"
```

---
