# AWS Multi-Region Disaster Recovery Setup
# Repository: https://github.com/Copubah/aws-multi-region-disaster-recovery

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    # Configure your backend here
    # bucket = "your-terraform-state-bucket"
    # key    = "disaster-recovery/terraform.tfstate"
    # region = "us-east-1"
    # encrypt = true
    # dynamodb_table = "terraform-locks"
  }
}

# Primary region provider
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

# DR region provider
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# Data sources
data "aws_availability_zones" "primary" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "dr" {
  provider = aws.dr
  state    = "available"
}

# Primary region infrastructure
module "primary_vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.primary
  }

  project_name        = var.project_name
  environment         = var.environment
  region              = var.primary_region
  vpc_cidr            = var.primary_vpc_cidr
  availability_zones  = data.aws_availability_zones.primary.names
  enable_nat_gateway  = true
  enable_vpn_gateway  = false
}

module "dr_vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.dr
  }

  project_name        = var.project_name
  environment         = var.environment
  region              = var.dr_region
  vpc_cidr            = var.dr_vpc_cidr
  availability_zones  = data.aws_availability_zones.dr.names
  enable_nat_gateway  = true
  enable_vpn_gateway  = false
}

# S3 with cross-region replication
module "s3_replication" {
  source = "./modules/s3"
  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  project_name = var.project_name
  environment  = var.environment
}

# RDS primary and read replica
module "rds" {
  source = "./modules/rds"
  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  project_name           = var.project_name
  environment            = var.environment
  primary_vpc_id         = module.primary_vpc.vpc_id
  primary_subnet_ids     = module.primary_vpc.private_subnet_ids
  dr_vpc_id              = module.dr_vpc.vpc_id
  dr_subnet_ids          = module.dr_vpc.private_subnet_ids
  db_instance_class      = var.db_instance_class
  db_name                = var.db_name
  db_username            = var.db_username
}

# ECS applications
module "primary_app" {
  source = "./modules/ecs"
  providers = {
    aws = aws.primary
  }

  project_name    = var.project_name
  environment     = var.environment
  region          = var.primary_region
  vpc_id          = module.primary_vpc.vpc_id
  public_subnet_ids = module.primary_vpc.public_subnet_ids
  private_subnet_ids = module.primary_vpc.private_subnet_ids
  container_image = var.container_image
  container_port  = var.container_port
}

module "dr_app" {
  source = "./modules/ecs"
  providers = {
    aws = aws.dr
  }

  project_name    = var.project_name
  environment     = var.environment
  region          = var.dr_region
  vpc_id          = module.dr_vpc.vpc_id
  public_subnet_ids = module.dr_vpc.public_subnet_ids
  private_subnet_ids = module.dr_vpc.private_subnet_ids
  container_image = var.container_image
  container_port  = var.container_port
}

# Route 53 with health checks and failover
module "route53" {
  source = "./modules/route53"

  domain_name           = var.domain_name
  primary_alb_dns_name  = module.primary_app.alb_dns_name
  primary_alb_zone_id   = module.primary_app.alb_zone_id
  dr_alb_dns_name       = module.dr_app.alb_dns_name
  dr_alb_zone_id        = module.dr_app.alb_zone_id
  health_check_path     = var.health_check_path
}