### IAM Roles ####
# IAM Role for EKS #
resource "aws_iam_role" "cluster_role" {
  name = "eks-cluster-role-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


### Worker Role ####

resource "aws_iam_role" "worker_role" {
  name = "eks-worker-role-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_policy1" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_policy2" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "worker_policy3" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

####### EKS Cluster #########

resource "aws_eks_cluster" "main" {
  name     = "${var.cluster_name}-${var.env_name}"
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = values(var.private_subnets_ids)

  }
}

# EKS Worker Node

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-managed-ng"
  node_role_arn   = aws_iam_role.worker_role.arn
  subnet_ids = values(var.private_subnets_ids)

  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"   # or SPOT

  disk_size = 20

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_capacity
    max_size     = var.max_capacity
  }
  update_config {
    max_unavailable = 1
  }
 tags = merge(
    var.tags,{ Name = "${var.cluster_name}-managed-node"}
  )
}
# key pair to log in
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

#### SG #######

resource "aws_security_group" "node_sg" {
  name   = "eks-node-sg-${var.env_name}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "node_sg_id" {
  value = aws_security_group.node_sg.id
}