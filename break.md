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
