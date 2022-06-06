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
  default = "east"
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
     Data Sources
*/
module "data" {
  source = "../../infra-aws-module-tf/data"
}

/*
  Gateway - VPC Peerings
*/
module "gateway-vpc-peering" {
  source = "../../infra-aws-module-tf/networking/vpc_peerings"

  name        = module.global_vars.tags["gateway_name"]
  deployment  = module.global_vars.tags["gateway_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  vpc_peering = {
    "GATEWAY-to-Range" = {
      name        = "GATEWAY-RANGE"
      vpc_id      = module.data.vpc_gateway.id
      peer_vpc_id = module.data.vpc_range.id
      auto_accept = true
    },
    "GATEWAY-to-GUAC" = {
      name        = "GATEWAY-GUAC"
      vpc_id      = module.data.vpc_gateway.id
      peer_vpc_id = module.data.vpc_guac.id
      auto_accept = true
    }
  }
}

/*
  RANGE - VPC Peerings
*/
module "range-vpc-peering" {
  source = "../../infra-aws-module-tf/networking/vpc_peerings"

  name        = module.global_vars.tags["range_name"]
  deployment  = module.global_vars.tags["range_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  vpc_peering = {
    "RANGE-to-GUAC" = {
      name        = "RANGE-GUAC"
      vpc_id      = module.data.vpc_range.id
      peer_vpc_id = module.data.vpc_guac.id
      auto_accept = true
    }
  }
}
