variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
variable "project_name" {
  description = "Name of the project"
  type        = string
}
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for ACM certificate"
  type        = string
}
variable "vpc_cidr" {
  description = "value of the VPC CIDR"
  type        = string
  validation {
    condition     = var.vpc_cidr != "" && length(regexall("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr)) > 0
    error_message = "Invalid CIDR block. Please provide a valid CIDR block."
  }
}
variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.31"
}
variable "enable_nat" {
  type        = bool
  description = "Enable/Disable of the NAT Gateway"
  default     = false
}
variable "publicEKS" {
  type        = bool
  description = "Enable/Disable of the public EKS cluster"
  default     = false
}
variable "nginx_controller_service_type" {
  type        = string
  description = "Service type for the nginx controller"
}
