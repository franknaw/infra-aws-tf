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
    Setup Route53
*/

resource "aws_route53_zone" "zone" {
  name = module.global_vars.route_domain

  vpc {
    vpc_id = module.data.vpc_gateway.id
  }
  vpc {
    vpc_id = module.data.vpc_range.id
  }
  vpc {
    vpc_id = module.data.vpc_guac.id
  }

  tags = {
    "Name"        = "aws_route53_zone"
    "Environment" = module.global_vars.environment[var.env]
  }
}
