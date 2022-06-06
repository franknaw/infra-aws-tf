
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.62"
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

// Landing-Page
resource "aws_ecr_repository" "ecr-landing-page" {
  name                 = module.global_vars.api_services["landing-page"]
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name        = module.global_vars.api_services["landing-page"],
    Environment = module.global_vars.environment[var.env]
  }
}

resource "aws_ecr_repository_policy" "ecr-repository-policy-landing-page" {
  repository = aws_ecr_repository.ecr-landing-page.name
  policy     = module.global_vars.ecr_policy
}
