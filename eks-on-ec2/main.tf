
provider "aws" {
  region = var.region
}

provider "rancher2" {
  api_url    = var.rancher_api_url
  access_key = var.rancher_access_key
  secret_key = var.rancher_secret_key
  insecure   = var.rancher_insecure
}

# Assume a role using AWS STS
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

resource "aws_iam_role" "eks_role" {
  name               = "${var.cluster_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "eks_policy_attachment" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "vpc_policy_attachment" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.5.0"

  name = "${var.cluster_name}-vpc"

  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway  = true
  enable_dns_hostnames = true
}

# Assume the role with AWS STS
data "aws_iam_policy_document" "sts_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = [aws_iam_role.eks_role.arn]
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_policy_attachment,
    aws_iam_role_policy_attachment.vpc_policy_attachment,
    module.vpc,
  ]
}

resource "rancher2_cluster" "eks_cluster" {
  name       = var.cluster_name
  driver     = "amazoneks"
  import     = false
  eks_config {
    assume_role {
      arn = aws_iam_role.eks_role.arn
    }
    region                    = var.region
    kubernetes_version        = "1.22"
    minimum_nodes             = 2
    maximum_nodes             = 4
    instance_type             = "t3.medium"
    node_volume_size          = 20
    node_subnet_ids           = module.vpc.private_subnets
    security_group_ids        = [module.vpc.default_security_group_id]
    service_role              = aws_iam_role.eks_role.arn
    subnet_ids                = module.vpc.public_subnets
    virtual_network           = module.vpc.vpc_id
    endpoint_public_access    = true
    endpoint_private_access   = true
  }
  depends_on = [aws_eks_cluster.eks_cluster]
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "rancher_cluster_id" {
  value = rancher2_cluster.eks_cluster.id
}
