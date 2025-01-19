###############################################################################
# Environment
###############################################################################
variable "region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "environment" {
  type = string
}

###############################################################################
# Network
###############################################################################
variable "vpc_cidr" {
  type = string
}
variable "num_zones" {
  type    = number
  default = 2
}
variable "single_nat_gateway" {
  type = bool
}
variable "enable_nat_gateway" {
  type = bool
}
variable "alb_name" {
  type        = string
  description = "Name for the ALB that is provisioned by the AWS load balancer controller"
  default     = "default-alb"
}

###############################################################################
# Project
###############################################################################
variable "project_name" {
  type = string
}
variable "enable_karpenter" {
  type = bool
}
variable "eks_managed_node_groups" {
  description = "(Optional) set of additional node pools for the cluster"
  type        = any
  default     = {}
}