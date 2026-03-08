terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ── VPC ──
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "auto-k8s-deployment-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["us-east-1a", "us-east-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = {
    Name = "auto-k8s-deployment-vpc"
  }
}

# ── EKS ──
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = "auto-k8s-deployment"
  cluster_version = "1.30"

  subnet_ids = module.vpc.public_subnets
  vpc_id     = module.vpc.vpc_id

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  access_entries = {
    cli_user = {
      principal_arn = "arn:aws:iam::<account-id>:user/<iam-username>"

      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }

    root_user = {
      principal_arn = "arn:aws:iam::<account-id>:root"

      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  eks_managed_node_groups = {
    worker_nodes = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.medium"]

      iam_role_additional_policies = {
        ecr_read = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  depends_on = [module.vpc]
}
