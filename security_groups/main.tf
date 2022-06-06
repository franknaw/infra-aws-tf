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
  Gateway - Security Groups
*/
module "gateway-security-groups" {
  source = "../../infra-aws-module-tf/networking/security_groups"

  name        = module.global_vars.tags["gateway_name"]
  deployment  = module.global_vars.tags["gateway_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]
  vpc_id      = module.data.vpc_gateway.id

  # Ingress rules for Private Security Group
  private_service_ingress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Private Ingress All"
      protocol    = "-1"
    }
  ]

  # Egress rules for Private Security Group
  private_service_egress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Private Egress All"
      protocol    = "-1"
    }
  ]

  # Ingress rules for Public Security Group
  public_service_ingress = [
    {
      port = 0
      cidr_blocks = [
        "0.0.0.0/0"
      ]
      description = "Public Ingress All"
      protocol    = "-1"
    }
  ]

  # Egress rules for Public Security Group
  public_service_egress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Public Egress All"
      protocol    = "-1"
    }
  ]
}

/*
  RANGE - Security Groups
*/
module "range-security-groups" {
  source = "../../infra-aws-module-tf/networking/security_groups"

  name        = module.global_vars.tags["range_name"]
  deployment  = module.global_vars.tags["range_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]
  vpc_id      = module.data.vpc_range.id

  # Ingress rules for Private Security Group
  private_service_ingress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Private Ingress All"
      protocol    = "-1"
    }
  ]

  # Egress rules for Private Security Group
  private_service_egress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Private Egress All"
      protocol    = "-1"
    }
  ]

  # Ingress rules for Public Security Group
  public_service_ingress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Public Ingress All"
      protocol    = "-1"
    }
  ]

  # Egress rules for Public Security Group
  public_service_egress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Public Egress All"
      protocol    = "-1"
    }
  ]
}

/*
  GUAC - Security Groups
*/
module "guac-security-groups" {
  source = "../../infra-aws-module-tf/networking/security_groups"

  name        = module.global_vars.tags["guac_name"]
  deployment  = module.global_vars.tags["guac_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]
  vpc_id      = module.data.vpc_guac.id

  # Ingress rules for Private Security Group
  private_service_ingress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Private Ingress All"
      protocol    = "-1"
    }
  ]

  # Egress rules for Private Security Group
  private_service_egress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Private Egress All"
      protocol    = "-1"
    }
  ]

  # Ingress rules for Public Security Group
  public_service_ingress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Public Ingress All"
      protocol    = "-1"
    }
  ]

  # Egress rules for Public Security Group
  public_service_egress = [
    {
      port = 0
      cidr_blocks = [
      "0.0.0.0/0"]
      description = "Public Egress All"
      protocol    = "-1"
    }
  ]
}


