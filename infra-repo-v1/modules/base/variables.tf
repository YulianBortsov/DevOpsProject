variable "environment" {
  description = "The environment in which the resources are deployed"
  type        = string
}
variable "project_name" {
  description = "The name of the project"
  type        = string
}
variable "region" {
  description = "The region in which the resources are deployed"
  type        = string
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}
variable "num_zones" {
  description = "The number of availability zones in the region"
  type        = number
}
variable "enable_karpenter" {
  description = "Enable the Karpenter autoscaler"
  type        = bool
}
variable "enable_nat_gateway" {
  description = "Enable NAT Gateways for private subnets"
  type        = bool
}
variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
}
variable "db_name" {
  description = "The name of the RDS database"
  type        = string
}
variable "eks_managed_node_groups" {
  description = "Managed node groups for the EKS cluster"
  type = map(object({
    instance_type = string
    min_size      = number
    max_size      = number
  }))
  default = {}

}

