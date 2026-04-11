# 🧪 Scenario 2 — Breaking NAT & Understanding Pod Scheduling Behavior in EKS

As part of my hands-on experiments with EKS, I wanted to understand how **networking (NAT) impacts pod scheduling and node behavior**.

So I intentionally broke the setup.

---

# 🔥 What I Did

I had a **highly available NAT setup (one NAT per AZ)**.

To simulate failure:

👉 I removed the NAT Gateway route from **one private subnet route table**

---

# 🚀 Deployment

Then I deployed an application with 2 replicas:

```bash
kubectl create deployment deployguard \
  --image=tehseen45/deployguard:v0.8 \
  --replicas=2
🤔 Expected Behavior

I expected:

Pods should distribute across nodes (different AZs)
No strict scheduling rules were defined
😳 Actual Behavior
kubectl get pods
deployguard-xxx   0/1   Pending
deployguard-yyy   1/1   Running
🔍 Deep Dive
kubectl get pods -o wide
NAME                     STATUS    NODE
deployguard-1            Running   ip-10-0-10-163
deployguard-2            Running   ip-10-0-10-163
deployguard-3            Pending   <none>

👉 Both running pods were scheduled on same node

👉 One pod was stuck in Pending

⚠️ Scheduler Events
0/2 nodes are available: Too many pods
🧠 What Was Happening?
1️⃣ Node Capacity Limit

From node description:

pods: 4

Each node supports only 4 pods max

Already running:

aws-node
kube-proxy
coredns
your pods

👉 Node reached max pod capacity

2️⃣ ENI / IP Exhaustion (Root Cause)

In AWS:

Each pod needs an IP
IPs come from ENI attached to instance

Small instance type:

t3.micro

👉 Very limited ENIs → limited pod capacity

3️⃣ NAT Failure Impact

The node in the AZ without NAT:

Cannot pull images
Cannot reach ECR / internet
Becomes unusable for new pods

👉 Scheduler avoids it

🔍 Validation Using My Tool

I used my preflight tool:

pip install git+https://github.com/syedtehseen-ai/EKS-Upgrade-Preflight-Tool.git

Run:

eks-preflight \
  --cluster deployguard-cluster-dev \
  --region ap-south-1 \
  --nodegroup deployguard-cluster-dev-managed-ng
📊 Output
Instance Type : t3.micro
Max Pods/Node : 4

Supported Pods : 3
Status         : ❌ FAIL (Insufficient capacity)
💡 Insight

👉 My instance type was too small
👉 ENI limits were restricting pod scheduling

✅ Fix — Upgrade Instance Type

I updated instance type in dev.tfvars:

t3.micro → t3.large
🔁 Re-run Preflight
Instance Type : t3.large
Max Pods/Node : 35

Supported Pods : 35
Status         : ✅ PASS
⚠️ Additional Issue Observed
NodeNotReady
Kubelet stopped posting node status

Also:

untolerated taint: node.cloudprovider.kubernetes.io/uninitialized

👉 This happened due to networking issues (NAT missing)

🔧 Final Fix — Restore NAT Route

I added back the route:

0.0.0.0/0 → NAT Gateway
🔄 Restart Deployment
kubectl rollout restart deploy deployguard
✅ Final Result
kubectl get pods -o wide
deployguard-1   Running   ip-10-0-10-191
deployguard-2   Running   ip-10-0-11-222

👉 Pods are now:

Running successfully
Distributed across nodes (multi-AZ)
🧠 End-to-End Flow (What Actually Happens)
kubectl
   ↓
API Server
   ↓
Scheduler
   ↓
Node
   ↓
containerd
   ↓
Internet (via NAT)
🔥 Key Learnings
NAT is critical for private subnet nodes
Pod scheduling depends on:
Node capacity
ENI/IP availability
Network reachability
Small instance types can silently limit scalability
Scheduler avoids unhealthy/unreachable nodes
🚀 Production Improvement
Reduce NAT Dependency

Instead of relying fully on NAT, use VPC Endpoints:

Required Endpoints:
ECR (api + dkr)
S3
STS
Example
aws ec2 create-vpc-endpoint \
  --vpc-id <vpc-id> \
  --service-name com.amazonaws.ap-south-1.ecr.api \
  --vpc-endpoint-type Interface
📌 Final Thought

This experiment showed me that:

👉 Kubernetes issues are often infrastructure problems in disguise

Breaking NAT didn’t just break networking —
it exposed:

scheduling behavior
ENI limits
node readiness issues

This is where DevOps becomes interesting —
when you connect Kubernetes + AWS networking + system limits together