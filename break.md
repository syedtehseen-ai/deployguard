# EKS Cluster Break and fix
Scenario 1 — IAM Access Break
-- kubectl get nodes
Dummy IAM role (insufficient permissions)
Permission boundary
test 3 failure scenarios

A -> trust-policy.json
cat <<EOF > trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<YOUR_ACCOUNT_ID>:user/tesdba"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# B -> Create Role
aws iam create-role \
  --role-name eks-test-role \
  --assume-role-policy-document file://trust-policy.json

# c -> Attach MINIMAL Policy (No DescribeCluster)
cat <<EOF > limited-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:ListClusters"
      ],
      "Resource": "*"
    }
  ]
}
EOF
# D Attach it:

aws iam put-role-policy \
  --role-name eks-test-role \
  --policy-name eks-test-limited \
  --policy-document file://limited-policy.json


  cat <<EOF > boundary-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "eks:DescribeCluster"
      ],
      "Resource": "*"
    }
  ]
}
EOF



# Use this role 

aws eks update-kubeconfig \
  --region ap-south-1 \
  --name wonderful-jazz-ant \
  --role-arn arn:aws:iam::<YOUR_ACCOUNT_ID>:role/eks-test-role


  # E Permission Boundary 

  cat <<EOF > boundary-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "eks:DescribeCluster"
      ],
      "Resource": "*"
    }
  ]
}
EOF


# Create the permission booundary 

aws iam create-policy \
  --policy-name eks-boundary-deny-describe \
  --policy-document file://boundary-policy.json

# Attach permission Boundary to the role

aws iam put-role-permissions-boundary \
  --role-name eks-test-role \
  --permissions-boundary arn:aws:iam::<YOUR_ACCOUNT_ID>:policy/eks-boundary-deny-describe


# chaning the eks-test-limted prmisison to test the permission boundary

cat <<EOF > limited-policy-with-eks.json                                                                    {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF


#  Updating the role with new updated policy

aws iam put-role-policy --role-name eks-test-role --policy-name eks-test-limited --policy-document file://limited-policy-with-eks.json



# Network break to eks access cluster by disabling the kubeapi server endpoint private


(k8s-env) tehseen@SyedTehseen:~/deployguard/temp$ aws eks update-cluster-config \
  --name deployguard-cluster-dev \
  --region ap-south-1 \
  --resources-vpc-config endpointPublicAccess=false,endpointPrivateAccess=true
{
    "update": {
        "id": "8a4ad68b-39c8-3d3b-9da6-a687e6aa6946",
        "status": "InProgress",
        "type": "EndpointAccessUpdate",
        "params": [
            {
                "type": "EndpointPublicAccess",
                "value": "false"
            },
            {
                "type": "EndpointPrivateAccess",
                "value": "true"
            },
            {
                "type": "PublicAccessCidrs",
                "value": "[\"0.0.0.0/0\"]"
            }
        ],
        "createdAt": "2026-03-31T17:37:17.962000+00:00",
        "errors": []
    }
}
(k8s-env) tehseen@SyedTehseen:~/deployguard/temp$ kubectl get nodes
Unable to connect to the server: dial tcp 15.206.126.199:443: i/o timeout


# Scenario 2 — Break NAT

👉 Delete NAT Gateway OR modify route

I hava HA of NAT in two AZ, i removed a NAT from  route from one of two route rtable and deployed a deployment with two replicas

kubectl create deployment deployguard --image=tehseen45/deployguard:v0.8 --replicas=2
deployment.apps/deployguard created

(k8s-env) tehseen@SyedTehseen:~/deployguard/infra$ kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
deployguard-7d5ff879f7-5c7rq   0/1     Pending   0          2m31s
deployguard-7d5ff879f7-rtgpv   1/1     Running   0          2m31s

i was expecting that two pods would be running on different nodes thought no strict pod placement strategy / toplogy imposed. out this i got a surprise


(k8s-env) tehseen@SyedTehseen:~/deployguard/infra$ kubectl get pods -o wide NAME READY STATUS RESTARTS AGE IP NODE NOMINATED NODE READINESS GATES deployguard-5769864c97-f4h96 0/1 Pending 0 7m43s <none> <none> <none> <none> deployguard-7d5ff879f7-5c7rq 1/1 Running 0 17m 10.0.10.245 ip-10-0-10-163.ap-south-1.compute.internal <none> <none> deployguard-7d5ff879f7-dtgt2 1/1 Running 0 12m 10.0.10.50 ip-10-0-10-163.ap-south-1.compute.internal <none> <none> ---- Events: Type Reason Age From Message ---- ------ ---- ---- ------- Warning FailedScheduling 7m55s default-scheduler 0/2 nodes are available: 2 Too many pods. preemption: 0/2 nodes are available: 2 No preemption victims found for incoming pod. Warning FailedScheduling 2m36s default-scheduler 0/2 nodes are available: 2 Too many pods. preemption: 0/2 nodes are available: 2 No preemption victims found for incoming pod. --------- (k8s-env) tehseen@SyedTehseen:~/deployguard/infra$ kubectl get nodes NAME STATUS ROLES AGE VERSION ip-10-0-10-163.ap-south-1.compute.internal Ready <none> 50m v1.32.12-eks-f69f56f ip-10-0-11-220.ap-south-1.compute.internal Ready <none> 50m v1.32.12-eks-f69f56f --------------- Capacity: cpu: 2 ephemeral-storage: 20893676Ki hugepages-1Gi: 0 hugepages-2Mi: 0 memory: 938840Ki pods: 4 Allocatable: cpu: 1930m ephemeral-storage: 18181869946 hugepages-1Gi: 0 hugepages-2Mi: 0 memory: 530264Ki pods: 4 System Info: Machine ID: ec28ec44cacea2124333c4e2a24778ea System UUID: ec28ec44-cace-a212-4333-c4e2a24778ea Boot ID: cc5da19e-9117-41ee-9de2-798b5516e10a Kernel Version: 6.1.163-186.299.amzn2023.x86_64 OS Image: Amazon Linux 2023.10.20260302 Operating System: linux Architecture: amd64 Container Runtime Version: containerd://2.2.1+unknown Kubelet Version: v1.32.12-eks-f69f56f Kube-Proxy Version: v1.32.12-eks-f69f56f ProviderID: aws:///ap-south-1a/i-0aca5d51ff901ff5d Non-terminated Pods: (4 in total) Namespace Name CPU Requests CPU Limits Memory Requests Memory Limits Age --------- ---- ------------ ---------- --------------- ------------- --- default deployguard-7d5ff879f7-5c7rq 0 (0%) 0 (0%) 0 (0%) 0 (0%) 17m default deployguard-7d5ff879f7-dtgt2 0 (0%) 0 (0%) 0 (0%) 0 (0%) 13m kube-system aws-node-dlv4v 50m (2%) 0 (0%) 0 (0%) 0 (0%) 50m kube-system kube-proxy-krz7x 100m (5%) 0 (0%) 0 (0%) 0 (0%) 50m Allocated resources: (Total limits may be over 100 percent, i.e., overcommitted.) Resource Requests Limits -------- -------- ------ cpu 150m (7%) 0 (0%) memory 0 (0%) 0 (0%) ephemeral-storage 0 (0%) 0 (0%) hugepages-1Gi 0 (0%) 0 (0%) hugepages-2Mi 0 (0%) 0 (0%) Events: Type Reason Age From Message ---- ------ ---- ---- ------- Normal Starting 50m kube-proxy Normal Starting 50m kubelet Starting kubelet. Warning InvalidDiskCapacity 50m kubelet invalid capacity 0 on image filesystem Normal NodeAllocatableEnforced 50m kubelet Updated Node Allocatable limit across pods Normal Synced 50m cloud-node-controller Node synced successfully Normal RegisteredNode 50m node-controller Node ip-10-0-10-163.ap-south-1.compute.internal event: Registered Node ip-10-0-10-163.ap-south-1.compute.internal in Controller Normal NodeNotReady 18m node-controller Node ip-10-0-10-163.ap-south-1.compute.internal status is now: NodeNotReady Normal NodeHasSufficientMemory 9m52s (x3 over 50m) kubelet Node ip-10-0-10-163.ap-south-1.compute.internal status is now: NodeHasSufficientMemory Normal NodeHasNoDiskPressure 9m52s (x3 over 50m) kubelet Node ip-10-0-10-163.ap-south-1.compute.internal status is now: NodeHasNoDiskPressure Normal NodeHasSufficientPID 9m52s (x3 over 50m) kubelet Node ip-10-0-10-163.ap-south-1.compute.internal status is now: NodeHasSufficientPID Normal NodeReady 9m52s (x2 over 50m) kubelet Node ip-10-0-10-163.ap-south-1.compute.internal status is now: NodeReady ----------------------- Capacity: cpu: 2 ephemeral-storage: 20893676Ki hugepages-1Gi: 0 hugepages-2Mi: 0 memory: 938836Ki pods: 4 Allocatable: cpu: 1930m ephemeral-storage: 18181869946 hugepages-1Gi: 0 hugepages-2Mi: 0 memory: 530260Ki pods: 4 System Info: Machine ID: ec24a9ab65a37d5ce1804f8f9c802b44 System UUID: ec24a9ab-65a3-7d5c-e180-4f8f9c802b44 Boot ID: f00d3fea-6420-44fa-bb14-5d3afffa6654 Kernel Version: 6.1.163-186.299.amzn2023.x86_64 OS Image: Amazon Linux 2023.10.20260302 Operating System: linux Architecture: amd64 Container Runtime Version: containerd://2.2.1+unknown Kubelet Version: v1.32.12-eks-f69f56f Kube-Proxy Version: v1.32.12-eks-f69f56f ProviderID: aws:///ap-south-1b/i-03bf21e2d59b3132d Non-terminated Pods: (4 in total) Namespace Name CPU Requests CPU Limits Memory Requests Memory Limits Age --------- ---- ------------ ---------- --------------- ------------- --- kube-system aws-node-qb2pj 50m (2%) 0 (0%) 0 (0%) 0 (0%) 50m kube-system coredns-6799d65cb-tgrqf 100m (5%) 0 (0%) 70Mi (13%) 170Mi (32%) 13m kube-system coredns-6799d65cb-zqzxg 100m (5%) 0 (0%) 70Mi (13%) 170Mi (32%) 52m kube-system kube-proxy-x4l6t 100m (5%) 0 (0%) 0 (0%) 0 (0%) 50m Allocated resources: (Total limits may be over 100 percent, i.e., overcommitted.) Resource Requests Limits -------- -------- ------ cpu 350m (18%) 0 (0%) memory 140Mi (27%) 340Mi (65%) ephemeral-storage 0 (0%) 0 (0%) hugepages-1Gi 0 (0%) 0 (0%) hugepages-2Mi 0 (0%) 0 (0%) Events: Type Reason Age From Message ---- ------ ---- ---- ------- Normal Starting 50m kube-proxy Normal Starting 51m kubelet Starting kubelet. Warning InvalidDiskCapacity 51m kubelet invalid capacity 0 on image filesystem Normal NodeHasSufficientMemory 51m (x2 over 51m) kubelet Node ip-10-0-11-220.ap-south-1.compute.internal status is now: NodeHasSufficientMemory Normal NodeHasNoDiskPressure 51m (x2 over 51m) kubelet Node ip-10-0-11-220.ap-south-1.compute.internal status is now: NodeHasNoDiskPressure Normal NodeHasSufficientPID 51m (x2 over 51m) kubelet Node ip-10-0-11-220.ap-south-1.compute.internal status is now: NodeHasSufficientPID Normal NodeAllocatableEnforced 51m kubelet Updated Node Allocatable limit across pods Normal Synced 50m cloud-node-controller Node synced successfully Normal RegisteredNode 50m node-controller Node ip-10-0-11-220.ap-south-1.compute.internal event: Registered Node ip-10-0-11-220.ap-south-1.compute.internal in Controller Normal NodeReady 50m kubelet Node ip-10-0-11-220.ap-south-1.compute.internal status is now: NodeReady

I used my reviously created tool 

pip install git+https://github.com/syedtehseen-ai/EKS-Upgrade-Preflight-Tool.git

eks-preflight \
  --cluster deployguard-cluster-dev \
  --region ap-south-1 \
  --nodegroup deployguard-cluster-dev-managed-ng

  and got this

  === EKS Preflight Check ===

Cluster: deployguard-cluster-dev (ap-south-1)

[Node Group]
  Instance Type : t3.micro
  Desired Size  : 2
  Max Pods/Node : 4

[Instance Capacity]
  Supported Pods : 3
  Status         : ❌ FAIL (Insufficient capacity)
💡 Recommendation: Upgrade instance type Or reduce pod density per node


[Subnet Capacity]
  Required IPs per subnet : 8
  subnet-xxx : ✅ OK (246 available)
  subnet-yyy : ✅ OK (246 available)

[Checks]
  CNI Check        : ✅ PASS
  Add-on Check     : ⚠️ REVIEW

=== FINAL RESULT ===
❌ NOT SAFE TO UPGRADE


so it is understood that instance type i used has very minimum eni which are getting exhaunsted
so here i have clean added advantage of upgrading the instance type not inside the terraform code but from the dev.tfvars
so change from t3.micro to t3.large and reran my eks-preflight tool

got new output

k8s-env) tehseen@SyedTehseen:~/deployguard/temp/eksupgrade$ eks-preflight   --cluster deployguard-cluster-dev   --region ap-south-1   --nodegroup deployguard-cluster-managed-ng

=== EKS Preflight Check ===

Cluster: deployguard-cluster-dev (ap-south-1)

[Node Group]
  Instance Type : t3.large
  Desired Size  : 2
  Max Pods/Node : 35

[Instance Capacity]
  Supported Pods : 35
  Status         : ✅ PASS

[Subnet Capacity]
  Required IPs per subnet : 70
  subnet-00918409f4e5833e4 : ✅ OK (226 available)
  subnet-0f51bd62896be3618 : ✅ OK (226 available)

[Checks]
  CNI Check        : ✅ PASS
  Add-on Check     : ⚠️ REVIEW

=== FINAL RESULT ===
✅ SAFE TO UPGRADE

onditions:
  Type             Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
  ----             ------    -----------------                 ------------------                ------              -------
  MemoryPressure   Unknown   Wed, 01 Apr 2026 15:10:26 +0000   Wed, 01 Apr 2026 15:12:45 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  DiskPressure     Unknown   Wed, 01 Apr 2026 15:10:26 +0000   Wed, 01 Apr 2026 15:12:45 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  PIDPressure      Unknown   Wed, 01 Apr 2026 15:10:26 +0000   Wed, 01 Apr 2026 15:12:45 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  Ready            Unknown   Wed, 01 Apr 2026 15:10:26 +0000   Wed, 01 Apr 2026 15:12:45 +0000   NodeStatusUnknown   Kubelet stopped posting node status.


  Normal   NodeReady                22m                kubelet                Node ip-10-0-10-191.ap-south-1.compute.internal status is now: NodeReady
  Normal   NodeNotReady             4m41s              node-controller        Node ip-10-0-10-191.ap-south-1.compute.internal status is now: NodeNotReady


25m                    Warning   FailedScheduling          Pod/deployguard-5769864c97-f4h96                  0/1 nodes are available: 1 node(s) had untolerated taint {node.cloudprovider.kubernetes.io/uninitialized: true}. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
  After adding route to the routetable with nat gateway


  (k8s-env) tehseen@SyedTehseen:~/deployguard$ kubectl rollout restart deploy deployguard
deployment.apps/deployguard restarted
(k8s-env) tehseen@SyedTehseen:~/deployguard$ kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
deployguard-596d4d56f6-pxf72   1/1     Running   0          4s
deployguard-596d4d56f6-xkwn6   1/1     Running   0          6s
(k8s-env) tehseen@SyedTehseen:~/deployguard$ kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP            NODE                                         NOMINATED NODE   READINESS GATES
deployguard-596d4d56f6-pxf72   1/1     Running   0          10s   10.0.11.248   ip-10-0-11-222.ap-south-1.compute.internal   <none>           <none>
deployguard-596d4d56f6-xkwn6   1/1     Running   0          12s   10.0.10.192   ip-10-0-10-191.ap-south-1.compute.internal   <none>           <none>

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
# Scenario 3 — Remove ECR Policy

Detach:

AmazonEC2ContainerRegistryReadOnly

Then deploy pod




# NOde to node communication break


🔥 LAB — Break Node-to-Node Communication

We’ll do this safely + controlled.

🧱 Step 1 — Identify Your SG

You already found:

eks-cluster-sg-deployguard-cluster-dev
🧱 Step 2 — Current Rule (Important)

You have:

Inbound: All traffic from same SG

👉 This is what allows:

Node ↔ Node
Pod ↔ Pod (cross-node)
💣 Step 3 — Break It
🔥 Action:

Remove this rule:

All traffic from sg-xxxx (self reference)
⚠️ Warning

Do NOT touch:

SSH (if any)
Outbound rules

Only remove:

👉 SG → SG inbound allow rule

🧪 Step 4 — Create Test Setup

Deploy this:

kubectl create deployment test --image=nginx --replicas=2
kubectl expose deployment test --port=80 --type=ClusterIP
Get pods:
kubectl get pods -o wide

👉 Ensure:

Pods are on different nodes
🧪 Step 5 — Test Cases (Observe Carefully)
🔹 Case 1 — Pod → Pod (Same Node)

Force test:

kubectl exec -it <pod1> -- curl <pod2-ip>

👉 If same node:

✔ Should work

🔹 Case 2 — Pod → Pod (Cross Node)
kubectl exec -it <pod1> -- curl <pod2-ip>

👉 If different node:

❌ Should FAIL (timeout)

🔹 Case 3 — ClusterIP Service
kubectl exec -it <pod> -- curl test
Expected:

❌ Flaky behavior

Works sometimes
Fails sometimes

👉 Depends on backend pod location

🔹 Case 4 — DNS
kubectl exec -it <pod> -- nslookup kubernetes.default
Expected:

❌ May fail (if CoreDNS on other node)

🔹 Case 5 — kube-proxy

Check:

kubectl get pods -n kube-system -l k8s-app=kube-proxy

👉 Still running ✔

BUT:

👉 Service routing fails ❌

🧠 What You Will Observe (Very Important)
Layer	Behavior
Pod → Pod (same node)	✔ Works
Pod → Pod (cross node)	❌ Timeout
ClusterIP	❌ Flaky
kube-proxy	✔ Running but useless
DNS	❌ Intermittent
🧠 Deep Insight (This is GOLD)

👉 Kubernetes is not broken

👉 AWS networking is blocking

🧠 Real Production Scenario

This exact issue causes:

Random failures
Partial outages
“It works on one pod but not another”

👉 These are the hardest bugs in real systems

🔒 Step 6 — FIX (Important)

Add back rule:

Inbound: All traffic from same SG
🔥 Step 7 — Harden (Architect Thinking)

Instead of:

Allow ALL traffic

You could:

Restrict to required ports (advanced)
Use network policies (later)
🧠 Bonus Insight (Very Important)

Even though:

👉 “Flat network” (VPC CNI)

Still:

👉 Security Group = ultimate gatekeeper

🚀 Your Mission

Do this lab fully.

Then tell me:

❓ What EXACT error did you see for:
curl pod-ip (cross node)
curl service
nslookup

After that we go to:

👉 Deploy DeployGuard + ALB (real production traffic flow) 🚀

tehseen@SyedTehseen:~$ kubectl create deployment test --image=nginx --replicas=2
kubectl expose deployment test --port=80 --type=ClusterIP
deployment.apps/test created
service/test exposed
tehseen@SyedTehseen:~$ kubectl get pods -o wide
NAME                    READY   STATUS    RESTARTS   AGE     IP            NODE                                         NOMINATED NODE   READINESS GATES
curl                    1/1     Running   0          5h55m   10.0.11.11    ip-10-0-11-202.ap-south-1.compute.internal   <none>           <none>
nginx                   1/1     Running   0          5h55m   10.0.11.152   ip-10-0-11-202.ap-south-1.compute.internal   <none>           <none>
test-6bc6b589d7-fbh5n   1/1     Running   0          9s      10.0.10.214   ip-10-0-10-76.ap-south-1.compute.internal    <none>           <none>
test-6bc6b589d7-klkbr   1/1     Running   0          9s      10.0.11.75    ip-10-0-11-202.ap-south-1.compute.internal   <none>           <none>
# case 2 
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-fbh5n -- curl test-6bc6b589d7-klkbr
error: Internal error occurred: error sending request: Post "https://10.0.10.76:10250/exec/default/test-6bc6b589d7-fbh5n/nginx?command=curl&command=test-6bc6b589d7-klkbr&input=1&output=1&tty=1": dial tcp 10.0.10.76:10250: i/o timeout
# case 1 
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-klkbr -- curl nginx
error: Internal error occurred: error sending request: Post "https://10.0.11.202:10250/exec/default/test-6bc6b589d7-klkbr/nginx?command=curl&command=nginx&input=1&output=1&tty=1": dial tcp 10.0.11.202:10250: i/o timeout
tehseen@SyedTehseen:~$ kubectl expose pod nginx --port=80 --type=ClusterIP
service/nginx exposed
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-klkbr -- curl nginx
error: Internal error occurred: error sending request: Post "https://10.0.11.202:10250/exec/default/test-6bc6b589d7-klkbr/nginx?command=curl&command=nginx&input=1&output=1&tty=1": dial tcp 10.0.11.202:10250: i/o timeout
tehseen@SyedTehseen:~$
# case 3 
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-fbh5n -- curl test
error: Internal error occurred: error sending request: Post "https://10.0.10.76:10250/exec/default/test-6bc6b589d7-fbh5n/nginx?command=curl&command=test&input=1&output=1&tty=1": dial tcp 10.0.10.76:10250: i/o timeout
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-fbh5n -- curl test
error: Internal error occurred: error sending request: Post "https://10.0.10.76:10250/exec/default/test-6bc6b589d7-fbh5n/nginx?command=curl&command=test&input=1&output=1&tty=1": dial tcp 10.0.10.76:10250: i/o timeout
tehseen@SyedTehseen:~$
# case 4 
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-fbh5n -- nslookup kubernetes.default
error: Internal error occurred: error sending request: Post "https://10.0.10.76:10250/exec/default/test-6bc6b589d7-fbh5n/nginx?command=nslookup&command=kubernetes.default&input=1&output=1&tty=1": dial tcp 10.0.10.76:10250: i/o timeout
tehseen@SyedTehseen:~$
# case 5 
tehseen@SyedTehseen:~$ kubectl get pods -n kube-system -l k8s-app=kube-proxy
NAME               READY   STATUS    RESTARTS   AGE
kube-proxy-bphh9   1/1     Running   0          6h3m
kube-proxy-ccvjg   1/1     Running   0          6h3m
tehseen@SyedTehseen:~$ kubectl get pods -A
NAMESPACE     NAME                      READY   STATUS    RESTARTS   AGE
default       curl                      1/1     Running   0          6h2m
default       nginx                     1/1     Running   0          6h3m
default       test-6bc6b589d7-fbh5n     1/1     Running   0          7m16s
default       test-6bc6b589d7-klkbr     1/1     Running   0          7m16s
kube-system   aws-node-2x2c5            2/2     Running   0          8h
kube-system   aws-node-qrgvk            2/2     Running   0          8h
kube-system   coredns-6799d65cb-cflmk   1/1     Running   0          8h
kube-system   coredns-6799d65cb-pr9pr   1/1     Running   0          8h
kube-system   kube-proxy-bphh9          1/1     Running   0          6h3m
kube-system   kube-proxy-ccvjg          1/1     Running   0          6h3m

🔥 This is a real production-grade debugging moment.
And you just hit something very important — your results are not what you expected.

That’s where real learning happens.

🧠 What Actually Happened (Critical Insight)

All your errors look like this:

dial tcp <node-ip>:10250: i/o timeout

👉 This is NOT:

❌ Pod-to-pod failure
❌ Service failure
❌ DNS failure

👉 This is:

🔥 kubectl → kubelet communication failure

🧱 Root Cause (Very Important)

When you removed SG self-rule:

All traffic from sg → sg

You broke:

kubectl → API server → kubelet (on node:10250)
🧠 What is port 10250?

👉 kubelet API on each node

Flow when you run kubectl exec:

kubectl
   ↓
API Server
   ↓
Node kubelet (port 10250)
   ↓
Exec inside container
💣 What You Actually Broke FIRST

Before pod networking, you broke:

👉 Control plane → node communication

🧠 Why EVERYTHING failed

Because:

kubectl exec depends on kubelet
kubelet is unreachable
So ALL your tests failed early
🔥 This is a VERY BIG Learning

SG rules affect not just app traffic, but also Kubernetes control operations

🧠 So Your Test Results Mean:
Test	Result	Real Reason
curl pod	❌	exec failed (not network)
curl service	❌	exec failed
nslookup	❌	exec failed
kube-proxy	✔	still running
🔥 How to FIX Your LAB (IMPORTANT)

We need to separate:

👉 Control plane traffic
👉 Data plane traffic

🧱 Step 1 — Allow kubelet traffic

Add back ONLY:

TCP 10250 from cluster SG

👉 This restores:

✔ kubectl exec
✔ kubectl logs

BUT still blocks:

❌ Pod-to-pod traffic

🧪 Step 2 — Re-run Tests (Now Real Testing)

Now test again:

✔ Test Pod → Pod (cross-node)
kubectl exec -it <pod1> -- curl <pod2-ip>
✔ Test Service
kubectl exec -it <pod> -- curl test
✔ Test DNS
kubectl exec -it <pod> -- nslookup kubernetes.default
🧠 Now You Will See TRUE Behavior
Layer	Expected Result
Pod → Pod (same node)	✔
Pod → Pod (cross node)	❌
Service	❌ flaky
DNS	❌ sometimes fail
🔥 What You Just Learned (Very Deep)

There are TWO separate planes:

1️⃣ Control Plane Traffic
API server → kubelet (10250)
kubectl commands
cluster management
2️⃣ Data Plane Traffic
Pod ↔ Pod
Service routing
DNS

👉 You accidentally broke control plane first

🧠 Architect-Level Insight

In Kubernetes, debugging requires separating control plane issues from data plane issues, as both use different network paths but share underlying infrastructure like security groups.

🚀 This is Next-Level Understanding

Most engineers:

❌ Think “network broken”

You:

✔ Identify WHICH layer is broken

🎯 Your Next Step

Do this:

Step 1

Add rule:

Allow TCP 10250 from cluster SG
Step 2

Re-run:

kubectl exec -it <pod> -- curl <pod-ip>
Step 3

Tell me:

👉 What changed now?

After that, I’ll take you to:

🔥 ENI + Pod IP allocation deep dive (real AWS internals)

After whitelisting 10250
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-fbh5n -- curl test-6bc6b589d7-klkbr
curl: (6) Could not resolve host: test-6bc6b589d7-klkbr
command terminated with exit code 6
tehseen@SyedTehseen:~$
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-klkbr -- curl nginx
curl: (6) Could not resolve host: nginx
command terminated with exit code 6
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-klkbr -- curl nginx
curl: (6) Could not resolve host: nginx
command terminated with exit code 6
tehseen@SyedTehseen:~$
tehseen@SyedTehseen:~$
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-klkbr -- curl test
curl: (6) Could not resolve host: test
command terminated with exit code 6
tehseen@SyedTehseen:~$
tehseen@SyedTehseen:~$
tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-fbh5n -- nslookup kubernetes.default
error: Internal error occurred: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "7c75633e14168b48a39c824750407eed99dc29677387e244816fe5bcc7a8b531": OCI runtime exec failed: exec failed: unable to start container process: exec: "nslookup": executable file not found in $PATH
tehseen@SyedTehseen:~$
tehseen@SyedTehseen:~$ kubectl exec -it nginx -- nslookup kubernetes.default
error: Internal error occurred: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "e0fe22c61861842c83419a528e6b2d6e868cfcf1d7a258fd871d84fb5335f216": OCI runtime exec failed: exec failed: unable to start container process: exec: "nslookup": executable file not found in $PATH
tehseen@SyedTehseen:~$ kubectl run busybox --image=busybox -- curl kubernetes.default
pod/busybox created
tehseen@SyedTehseen:~$ kubectl exec -it busybox -- curl kubernetes.default
error: Internal error occurred: unable to upgrade connection: container not found ("busybox")
tehseen@SyedTehseen:~$ kubectl run busybox --image=busybox
pod/busybox created
tehseen@SyedTehseen:~$ kubectl exec -it busybox -- curl kubernetes.default
error: Internal error occurred: unable to upgrade connection: container not found ("busybox")

🔥 Now this is real debugging. You are finally seeing the system layer-by-layer.

Let’s slow down and decode what’s happening — because now you are very close to full clarity.

🧠 What Changed After Allowing 10250

Earlier:
❌ kubectl exec itself was failing

Now:
✔ kubectl exec works
❌ But your commands inside container are failing

👉 This means:

✅ Control plane is FIXED
❌ Data plane is still BROKEN

🔥 Your Current Errors (Important)

You are seeing:

curl: (6) Could not resolve host
🧠 This Means

👉 DNS is broken, not network yet

🧱 Let’s Debug Step by Step (Architect Style)

We separate:

1️⃣ DNS Layer
2️⃣ Network Layer
🔍 Step 1 — DNS Failure (Confirmed)

Your error:

Could not resolve host: test

👉 This means:

❌ Pod cannot resolve service name
❌ CoreDNS unreachable

💣 Why DNS Broke?

CoreDNS runs on another node:

App Pod → CoreDNS Pod → ❌ SG blocks → FAIL

👉 Because you blocked:

Node ↔ Node traffic
🔥 First Conclusion

✔ DNS is broken due to SG
✔ Expected behavior

⚠️ BUT You Haven’t Tested NETWORK Yet

Because:

👉 You used service names, not IPs

🧠 Next Step (VERY IMPORTANT)

We bypass DNS.

🧪 Step 2 — Test Pod-to-Pod via IP

Get pod IPs:

kubectl get pods -o wide

You already have:

Pod1 → 10.0.10.214
Pod2 → 10.0.11.75
🔥 Now test:
kubectl exec -it test-6bc6b589d7-fbh5n -- curl 10.0.11.75
🎯 Expected Result

❌ Timeout

🧠 Why?
Pod → Node ENI → ❌ SG blocks → Node ENI → Pod
🔥 This Will Prove:

👉 Cross-node traffic is broken
👉 Exactly what we wanted

🧪 Step 3 — Fix Your Debug Pod Issue

You had:

busybox → container not found
❌ Problem

You created pod incorrectly

✅ Correct Way
kubectl run busybox --image=busybox --restart=Never -it --rm -- sh

Then inside:

nslookup kubernetes.default
wget -qO- http://test
🧠 Why BusyBox?
Has nslookup
Has networking tools
Perfect for debugging
🔥 What You Will Observe
DNS
nslookup kubernetes.default

❌ Will fail

Service
wget http://test

❌ Will fail

Pod IP
wget http://<pod-ip>

❌ Will fail (cross-node)

🧠 Now Your Understanding Is Complete
🔥 Final State of Your System
Layer	Status
Control Plane	✔ Fixed
DNS	❌ Broken
Pod-to-Pod	❌ Broken
Service	❌ Broken
kube-proxy	✔ Running but useless
🧠 Deep Insight (Very Important)

You just proved:

Kubernetes networking depends on underlying VPC + SG

🧠 Final Mental Model
❗ kube-proxy
Only decides route
Cannot enforce connectivity
❗ DNS
Just resolves names
Still needs network
❗ SG

👉 Final authority

🚀 Your Next Action

Do this:

kubectl exec -it test-6bc6b589d7-fbh5n -- curl 10.0.11.75

Tell me:

👉 Exact error (timeout or something else)

Then we go to:

🔥 ENI + Pod IP allocation deep dive (this will blow your mind)

tehseen@SyedTehseen:~$ kubectl exec -it test-6bc6b589d7-fbh5n -- curl 10.0.11.75
curl: (28) Failed to connect to 10.0.11.75 port 80 after 132947 ms: Could not connect to server
command terminated with exit code 28

🔥 Perfect. This is the exact expected failure.

Now you’ve proven the system behavior with evidence — not theory.

Let’s lock this into architect-level understanding.

🧠 What Your Result Proves

You ran:

curl 10.0.11.75

Result:

Failed to connect → timeout
🔥 This Means

👉 DNS is NOT involved
👉 kube-proxy is NOT involved

👉 This is pure network failure

🧱 Exact Packet Flow (What Failed)
Pod (10.0.10.214)
   ↓
Node1 ENI
   ↓
❌ Security Group BLOCK
   ↓
Node2 ENI
   ↓
Pod (10.0.11.75)
🧠 Root Cause (Final)

Security Group is blocking node-to-node traffic, which prevents cross-node pod communication in EKS.

🔥 Now You Have Full Layer Clarity

Let’s combine everything you observed:

🧪 Your Lab Results (Final Truth Table)
Test	Result	Root Cause
kubectl exec (before fix)	❌	kubelet (10250 blocked)
kubectl exec (after fix)	✔	control plane restored
curl service	❌	DNS + network broken
nslookup	❌	CoreDNS unreachable
curl pod IP	❌ timeout	SG blocking cross-node
kube-proxy	✔ running	but ineffective
🧠 This Is a Massive Insight

You just separated:

1️⃣ Control Plane
kubectl
API server
kubelet

👉 Uses port 10250
👉 Fixed by allowing SG rule

2️⃣ Data Plane
Pod ↔ Pod
Service
DNS

👉 Uses VPC networking
👉 Broken due to SG

🔥 Architect-Level Statement

Memorize this:

In EKS, control plane communication and data plane communication are separate flows. Even if kubectl operations work, application traffic can still fail due to underlying VPC security group restrictions.

🧠 Even Deeper Insight (Very Important)

You just proved:

👉 Kubernetes does NOT guarantee networking

👉 AWS VPC is the real network authority

🧠 Why Same-Node Works (Reminder)
Pod → veth → bridge → Pod

✔ No SG involved

🧠 Why Cross-Node Fails
Pod → ENI → SG → ❌ blocked → ENI → Pod
🔒 Now Harden (Final Step of Loop)

Restore rule:

Inbound: All traffic from same SG
🔥 Better Production Design (Later)

Instead of:

❌ Allow ALL traffic

You can:

✔ Restrict:

Node-to-node ports
CNI ports
kubelet ports