locals {
    environment = "dev"
    region = "us-east-1"
    domain_name = "ybort.shop"
    project_name = "DevOpsProject"
    vpc_cidr = "10.0.0.0/16"
    enable_rds = false
    db_name = "taskManagerDB"
    enable_nat_gateway = true
    single_nat_gateway = true
    enable_karpenter = true
    enable_argocd = true
    enable_aws_load_balancer_controller = true
    enable_external_secrets = true
    num_zones = 2
    karpenter_config = {
        default = {
            tainted = false
            taints = {
                    key = "should"
                }
            labels = {
                    key = "should-not"
                    value = "see"
                }
            disruption = true
            labeled = false
            amiAlias = "bottlerocket@latest"
            instance_category = {
                operator = "In"
                values = ["t", "m", "c"]
            }
            instance_size = {
                operator = "NotIn"
                values = ["small", "medium", "nano", "micro"]
            }
            instance_cpu = {
                operator = "In"
                values = ["2", "4", "8", "16"]
            }
            instance_hypervisor = {
                operator = "In"
                values = ["nitro"]
            }
            instance_generation = {
                operator = "Gt"
                values = ["2"]
            }
            capacity_type = {
                operator = "In"
                values = ["spot"]
            }
            limits = {
                cpu = 500
                memory = "100Gi"
            }
        }
        critical = {
            tainted = true
            taints = {
                    key = "aws-lbc"
                }
            disruption = true
            labeled = true
            labels = {
                    key = "workload-type"
                    value = "critical"
                }
            amiAlias = "bottlerocket@latest"
            instance_category = {
                operator = "In"
                values = ["t"]
            }
            instance_size = {
                operator = "NotIn"
                values = ["small", "nano", "micro"]
            }
            instance_cpu = {
                operator = "In"
                values = ["2", "4", "8"]
            }
            instance_hypervisor = {
                operator = "In"
                values = ["nitro"]
            }
            instance_generation = {
                operator = "Gt"
                values = ["2"]
            }
            capacity_type = {
                operator = "In"
                values = ["on-demand"]
            }
            limits = {
                cpu = 500
                memory = "100Gi"
            }
        }
}
}