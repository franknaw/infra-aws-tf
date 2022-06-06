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

data "aws_security_group" "security_group_gateway_private" {
  tags = {
    Name = "GATEWAY-Private-SG"
  }
}


/*
  Gateway - VPC Endpoints
*/
module "gateway-vpc-endpoints" {
  source = "../../infra-aws-module-tf/networking/vpc_endpoints"

  name        = module.global_vars.tags["gateway_name"]
  deployment  = module.global_vars.tags["gateway_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  # Configure VPC Endpoints (Optional)
  vpc_endpoints = {
    "S3" = {
      name              = "S3"
      service_name      = "com.amazonaws.${module.global_vars.region[var.region]}.s3"
      vpc_endpoint_type = "Gateway"
      vpc_id            = module.data.vpc_gateway.id
    },
    "ECR-API" = {
      name                = "ECR-API"
      service_name        = "com.amazonaws.${module.global_vars.region[var.region]}.ecr.api"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
      vpc_id              = module.data.vpc_gateway.id
      subnet_ids          = module.data.vpc_gateway_subs_private
      security_group_ids  = [data.aws_security_group.security_group_gateway_private.id]
    },
    "ECRDKR-API" = {
      name                = "ECRDKR-API"
      service_name        = "com.amazonaws.${module.global_vars.region[var.region]}.ecr.dkr"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
      vpc_id              = module.data.vpc_gateway.id
      subnet_ids          = module.data.vpc_gateway_subs_private
      security_group_ids  = [data.aws_security_group.security_group_gateway_private.id]
    },
    "SECRETS-API" = {
      name                = "SECRETS-API"
      service_name        = "com.amazonaws.${module.global_vars.region[var.region]}.secretsmanager"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
      vpc_id              = module.data.vpc_gateway.id
      subnet_ids          = module.data.vpc_gateway_subs_private
      security_group_ids  = [data.aws_security_group.security_group_gateway_private.id]
    },
    "LOGS-API" = {
      name                = "LOGS-API"
      service_name        = "com.amazonaws.${module.global_vars.region[var.region]}.logs"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
      vpc_id              = module.data.vpc_gateway.id
      subnet_ids          = module.data.vpc_gateway_subs_private
      security_group_ids  = [data.aws_security_group.security_group_gateway_private.id]
    },
    "SSM-API" = {
      name                = "SSM-API"
      service_name        = "com.amazonaws.${module.global_vars.region[var.region]}.ssm"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
      vpc_id              = module.data.vpc_gateway.id
      subnet_ids          = module.data.vpc_gateway_subs_private
      security_group_ids  = [data.aws_security_group.security_group_gateway_private.id]
    },
    "EFS-API" = {
      name                = "EFS-API"
      service_name        = "com.amazonaws.${module.global_vars.region[var.region]}.elasticfilesystem"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
      vpc_id              = module.data.vpc_gateway.id
      subnet_ids          = module.data.vpc_gateway_subs_private
      security_group_ids  = [data.aws_security_group.security_group_gateway_private.id]
    }
    # Made manually
    # Error creating VPC Endpoint: InvalidParameter: Service com.amazonaws.us-gov-west-1.email-smtp only supports the full-access endpoint policy.
    //    "SMTP-API" = {
    //      name                = "SMTP-API"
    //      service_name        = "com.amazonaws.${module.global_vars.environment[var.env]}.email-smtp"
    //      vpc_endpoint_type   = "Interface"
    //      private_dns_enabled = true
    //      vpc_id              = module.data.vpc_gateway.id
    //      subnet_ids          = module.data.vpc_gateway_subs_private
    //      security_group_ids  = [data.aws_security_group.security_group_gateway_private.id]
    //    }
  }
}



