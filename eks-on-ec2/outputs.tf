
output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "rancher_cluster_id" {
  value = rancher2_cluster.eks_cluster.id
}
