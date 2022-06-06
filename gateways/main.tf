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
  Gateway - Internet and Nat Gateways
*/
module "gateway-gateways" {
  source = "../../infra-aws-module-tf/networking/gateways"

  name             = module.global_vars.tags["gateway_name"]
  deployment       = module.global_vars.tags["gateway_deployment"]
  environment      = module.global_vars.environment[var.env]
  subsystem        = module.global_vars.tags["subsystem"]
  vpc_id           = module.data.vpc_gateway.id
  public_subnet_id = tolist(module.data.vpc_gateway_subs_public)[0]
}

/*
  Range - Internet and Nat Gateways
*/

module "range-gateways" {
  source = "../../infra-aws-module-tf/networking/gateways"

  name             = module.global_vars.tags["range_name"]
  deployment       = module.global_vars.tags["range_deployment"]
  environment      = module.global_vars.environment[var.env]
  subsystem        = module.global_vars.tags["subsystem"]
  vpc_id           = module.data.vpc_range.id
  public_subnet_id = tolist(module.data.vpc_range_subs_public)[0]
}
/*
  Guacamole - Internet and Nat Gateways
*/
module "guac-gateways" {
  source = "../../infra-aws-module-tf/networking/gateways"

  name             = module.global_vars.tags["guac_name"]
  deployment       = module.global_vars.tags["guac_deployment"]
  environment      = module.global_vars.environment[var.env]
  subsystem        = module.global_vars.tags["subsystem"]
  vpc_id           = module.data.vpc_guac.id
  public_subnet_id = tolist(module.data.vpc_guac_subs_public)[0]
}
