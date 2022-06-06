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

locals {
  certificate_name = "infra-dev.org"
}

resource "aws_iam_server_certificate" "certificate" {
  name      = "gateway-alb-certificate_${var.region}-${var.env}"
  certificate_body = file("certs/${var.region}-${var.env}-certificate.crt")
  private_key = file("certs/${var.region}-${var.env}-privateKey.key")

  tags = {
    "Name"        = "GATEWAY-CERT"
    "Environment" = module.global_vars.environment[var.env]
  }

}

output "certificate" {
  value = aws_iam_server_certificate.certificate.arn
}

/*
   GATEWAY-ALB SG
*/

resource "aws_security_group" "gateway-alb-sg" {
  vpc_id = module.data.vpc_gateway.id
  name   = "GATEWAY-ALB-SG"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "172.111.4.104/32"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    "Name"        = "GATEWAY-ALB-SG"
    "Environment" = module.global_vars.environment[var.env]
  }
}

/*
    Load Balancer
*/
module "alb" {
  source = "../../infra-aws-module-tf/compute/load_balancer/load_balancers"

  name        = module.global_vars.tags["gateway_name"]
  deployment  = module.global_vars.tags["gateway_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  lb_name                       = "ALB"
  lb_enable_deletion_protection = false
  lb_idle_timeout               = 200
  lb_internal                   = false
  lb_load_balancer_type         = "application"
  lb_security_groups            = [aws_security_group.gateway-alb-sg.id]
  lb_subnets                    = module.data.vpc_gateway_subs_public

  lb_log_enabled = false
  lb_log_bucket  = "" #aws_s3_bucket.alb_s3.bucket
  lb_log_prefix  = "" #"dev-lb"

}

/*
    Load Balancer Target Groups
*/
module "alb_tg" {
  source = "../../infra-aws-module-tf/compute/load_balancer/load_balancer_target_groups"

  name        = module.global_vars.tags["gateway_name"]
  deployment  = module.global_vars.tags["gateway_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  aws_lb_tg = [
    {
      name                          = "landing-page"
      port                          = 8080
      protocol                      = "HTTP"
      vpc_id                        = module.data.vpc_gateway.id
      load_balancing_algorithm_type = "least_outstanding_requests"
      target_type                   = "ip"
      stickiness_enabled            = false
      stickiness_type               = "lb_cookie"
      health_check_protocol         = "HTTP"
      health_check_path             = "/"
      health_check_matcher          = "200"
      health_check_port             = 8080
      health_check_timeout          = 30
      health_check_interval         = 31
    },
    {
      name                          = "nginx-lab"
      port                          = 8443
      protocol                      = "HTTPS"
      vpc_id                        = module.data.vpc_gateway.id
      load_balancing_algorithm_type = "least_outstanding_requests"
      target_type                   = "ip"
      stickiness_enabled            = false
      stickiness_type               = "lb_cookie"
      health_check_protocol         = "HTTPS"
      health_check_path             = "/health"
      health_check_matcher          = "200"
      health_check_port             = 8443
      health_check_timeout          = 30
      health_check_interval         = 31
    },
    {
      name                          = "range-micro-1"
      port                          = 8080
      protocol                      = "HTTP"
      vpc_id                        = module.data.vpc_gateway.id
      load_balancing_algorithm_type = "least_outstanding_requests"
      target_type                   = "ip"
      stickiness_enabled            = false
      stickiness_type               = "lb_cookie"
      health_check_protocol         = "HTTP"
      health_check_path             = "/health"
      health_check_matcher          = "200"
      health_check_port             = 8080
      health_check_timeout          = 30
      health_check_interval         = 31
    },
    {
      name                          = "range-micro-2"
      port                          = 8080
      protocol                      = "HTTP"
      vpc_id                        = module.data.vpc_gateway.id
      load_balancing_algorithm_type = "least_outstanding_requests"
      target_type                   = "ip"
      stickiness_enabled            = false
      stickiness_type               = "lb_cookie"
      health_check_protocol         = "HTTP"
      health_check_path             = "/health"
      health_check_matcher          = "200"
      health_check_port             = 8080
      health_check_timeout          = 30
      health_check_interval         = 31
    }
  ]
}

/*
    Load Balancer Target Group Attachments
*/
module "alb_tg_attachments" {
  source = "../../infra-aws-module-tf/compute/load_balancer/load_balancer_target_group_attachments"

  name        = module.global_vars.tags["gateway_name"]
  deployment  = module.global_vars.tags["gateway_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  aws_lb_tg_attachment = [
    {
      target_group_arn             = module.alb_tg.aws_lb_target_groups[1].arn
      attachment_target_id         = "172.31.8.122" # Nginx
      attachment_port              = 8443
      attachment_availability_zone = "all"
    }
  ]
}


/*
    Load Balancer Listeners
*/

resource "aws_lb_listener" "HTTP-Listener" {
  load_balancer_arn = module.alb.aws_lb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = module.alb.aws_lb[0].dns_name
      query       = ""
      path        = "/"

    }
  }
}

module "alb_tg_listeners" {
  source = "../../infra-aws-module-tf/compute/load_balancer/load_balancer_listeners"

  name        = module.global_vars.tags["gateway_name"]
  deployment  = module.global_vars.tags["gateway_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  aws_lb_listeners = [
    {
      name                     = "HTTPS-Listener"
      load_balancer_arn        = module.alb.aws_lb[0].arn
      port                     = "443"
      protocol                 = "HTTPS"
      ssl_policy               = "ELBSecurityPolicy-2016-08"
      certificate_arn          = aws_iam_server_certificate.certificate.arn
      default_type             = "forward"
      default_target_group_arn = module.alb_tg.aws_lb_target_groups[0].arn
    }
  ]
}

/*
    Load Balancer Listener Rules
*/

module "alb_tg_listener_rules" {
  source = "../../infra-aws-module-tf/compute/load_balancer/load_balancer_listener_rules"

  name        = module.global_vars.tags["gateway_name"]
  deployment  = module.global_vars.tags["gateway_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  aws_lb_listener_rules = [
    {
      name                          = "nginx-lab"
      listener_arn                  = module.alb_tg_listeners.aws_lb_listener[0].arn
      action_type                   = "forward"
      action_target_group_arn       = module.alb_tg.aws_lb_target_groups[1].arn
      condition_path_pattern_values = ["/web*"]
    },
    {
      name                          = "guacamole"
      listener_arn                  = module.alb_tg_listeners.aws_lb_listener[0].arn
      action_type                   = "forward"
      action_target_group_arn       = module.alb_tg.aws_lb_target_groups[1].arn
      condition_path_pattern_values = ["/guacamole*"]
    },
    {
      name                          = "range-micro-1"
      listener_arn                  = module.alb_tg_listeners.aws_lb_listener[0].arn
      action_type                   = "forward"
      action_target_group_arn       = module.alb_tg.aws_lb_target_groups[2].arn
      condition_path_pattern_values = ["/range1*"]
    },
    {
      name                          = "range-micro-2"
      listener_arn                  = module.alb_tg_listeners.aws_lb_listener[0].arn
      action_type                   = "forward"
      action_target_group_arn       = module.alb_tg.aws_lb_target_groups[3].arn
      condition_path_pattern_values = ["/range2*"]
    }
  ]
}

