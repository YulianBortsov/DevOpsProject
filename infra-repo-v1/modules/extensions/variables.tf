variable "region" {
  description = "The region in which the resources are deployed"
  type        = string
}
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}
variable "cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  type        = string
}
variable "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  type        = string
}
variable "cluster_oidc_provider_arn" {
  description = "The OIDC provider ARN of the EKS cluster"
  type        = string
}
variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}
variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
}
variable "enable_aws_load_balancer_controller" {
  description = "Enable the AWS Load Balancer Controller"
  type        = bool
}
variable "enable_external_secrets" {
  description = "Enable External Secrets"
  type        = bool
}
variable "environment" {
  description = "The environment in which the resources are deployed"
  type        = string
}
variable "project_name" {
  description = "The name of the project"
  type        = string
}
variable "domain_name" {
  description = "The domain name for the Route 53 hosted zone"
  type        = string
}
variable "cluster_certificate_authority_data" {
  description = "Certificate authority data for the cluster"
  type = string
}

