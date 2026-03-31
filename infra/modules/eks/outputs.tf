output "cluster_role_arn" {
  value = aws_iam_role.cluster_role.arn
}

output "worker_role_arn" {
  value = aws_iam_role.worker_role.arn
}

output "worker_role_name" {
  value = aws_iam_role.worker_role.name
}
