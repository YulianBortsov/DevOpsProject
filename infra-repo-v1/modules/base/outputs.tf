output "region" {
  description = "AWS region"
  value       = var.region
}
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}
output "cluster_oidc_provider_arn" {
  description = "EKS cluster OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}
output "cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}
output "environment" {
  description = "The environment in which the resources are deployed"
  value       = var.environment
}
output "project_name" {
  description = "The name of the project"
  value       = var.project_name
}
output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
  description = "Certificate authority data for the cluster"
}