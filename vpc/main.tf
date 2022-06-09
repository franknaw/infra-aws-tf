terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.54"
    }
  }
}

provider "aws" {
  region  = module.global_vars.region[var.region]
  profile = "infra"
}

variable "env" {
  type    = string
  default = ""
}

output "env" {
  value = var.env
}

variable "region" {
  type    = string
  default = ""
}

output "region" {
  value = module.global_vars.region[var.region]
}

/*
  Global Variables
*/
module "global_vars" {
  source = "../../infra-aws-module-tf/global_vars"
}

/*
  Gateway - VPC
*/
module "gateway-vpc" {
  source = "../../infra-aws-module-tf/networking/vpc"

  name                       = module.global_vars.tags["gateway_name"]
  deployment                 = module.global_vars.tags["gateway_deployment"]
  environment                = module.global_vars.environment[var.env]
  subsystem                  = module.global_vars.tags["subsystem"]
  vpc_cidr_block             = module.global_vars.cidr_block_vpc[module.global_vars.environment[var.env]]["gateway"]
  private_subnet_cidr_blocks = module.global_vars.cidr_block_sub[module.global_vars.environment[var.env]]["gateway_private"]
  public_subnet_cidr_blocks  = module.global_vars.cidr_block_sub[module.global_vars.environment[var.env]]["gateway_public"]
  region                     = module.global_vars.region[var.region]
}


/*
  RANGE - VPC
*/
module "range-vpc" {
  source = "../../infra-aws-module-tf/networking/vpc"

  name                       = module.global_vars.tags["range_name"]
  deployment                 = module.global_vars.tags["range_deployment"]
  environment                = module.global_vars.environment[var.env]
  subsystem                  = module.global_vars.tags["subsystem"]
  vpc_cidr_block             = module.global_vars.cidr_block_vpc[module.global_vars.environment[var.env]]["range"]
  private_subnet_cidr_blocks = module.global_vars.cidr_block_sub[module.global_vars.environment[var.env]]["range_private"]
  public_subnet_cidr_blocks  = module.global_vars.cidr_block_sub[module.global_vars.environment[var.env]]["range_public"]
  region                     = module.global_vars.region[var.region]
  subnet_tags = {
    "kubernetes.io/cluster/${module.global_vars.cluster_name}-${module.global_vars.environment[var.env]}" = "shared"
    "kubernetes.io/role/elb" = 1
  }
}

/*
  GUACAMOLE - VPC
*/
module "guac-vpc" {
  source = "../../infra-aws-module-tf/networking/vpc"

  name                       = module.global_vars.tags["guac_name"]
  deployment                 = module.global_vars.tags["guac_deployment"]
  environment                = module.global_vars.environment[var.env]
  subsystem                  = module.global_vars.tags["subsystem"]
  vpc_cidr_block             = module.global_vars.cidr_block_vpc[module.global_vars.environment[var.env]]["guac"]
  private_subnet_cidr_blocks = module.global_vars.cidr_block_sub[module.global_vars.environment[var.env]]["guac_private"]
  public_subnet_cidr_blocks  = module.global_vars.cidr_block_sub[module.global_vars.environment[var.env]]["guac_public"]
  region                     = module.global_vars.region[var.region]
}
