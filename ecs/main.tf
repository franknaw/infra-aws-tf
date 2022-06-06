
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
  This needs to be created in IAM.  TODO programmatically generate it.
  Role: ECSTaskExecutionRole  - select trusted entity ECS
    AWS managed policy: AmazonElasticFileSystemFullAccess
    AWS managed policy: EC2InstanceProfileForImageBuilderECRContainerBuilds
    AWS managed policy: SecretsManagerReadWrite
    AWS managed policy: CloudWatchLogsFullAccess
    AWS managed policy: AmazonECSTaskExecutionRolePolicy
    AWS managed policy: AmazonECS_FullAccess
    AWS managed policy: AmazonS3FullAccess
*/

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ECSTaskExecutionRole"
}

output "ecs_task_execution_role" {
  value = data.aws_iam_role.ecs_task_execution_role.arn
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
   LMS ESC SG
*/

resource "aws_security_group" "gateway-ecs-sg" {
  vpc_id = module.data.vpc_gateway.id
  name   = "GATEWAY-ECS-SG"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    "Name"        = "GATEWAY-ECS-SG"
    "Environment" = module.global_vars.environment[var.env]
  }
}

/*
    Setup Cloudwatch Log Groups
*/

resource "aws_cloudwatch_log_group" "landing-page" {
  name              = "/ecs/landing-page"
  retention_in_days = 30
}

/*
    Setup Route53
*/

data "aws_route53_zone" "zone" {
  name         = module.global_vars.route_domain
  private_zone = true
}

output "zone_id" {
  value = data.aws_route53_zone.zone.zone_id
}

resource "aws_route53_record" "landing-page" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "landing-page.${module.global_vars.route_domain}"
  type    = "A"
  ttl     = "300"
  records = ["172.64.1.105"]
}

/*
   GATEWAY Cluster
*/

resource "aws_ecs_cluster" "gateway-cluster" {
  name = "gateway-cluster"

  tags = {
    Name        = "GATEWAY-Cluster"
    Environment = module.global_vars.environment[var.env]
  }
}


/*
   landing-page - GATEWAY
*/


data "aws_lb_target_group" "lp-tg" {
  name = "landing-page"
}

output "landing-page-aws_lb_target_group" {
  value = data.aws_lb_target_group.lp-tg.arn
}

data "aws_ecr_repository" "landing-page-repo" {
  name = "landing-page"
}

output "landing-page-repo" {
  value = data.aws_ecr_repository.landing-page-repo.repository_url
}

data "aws_ecr_image" "landing-page-image" {
  repository_name = data.aws_ecr_repository.landing-page-repo.name
  image_tag       = "latest"
}

output "landing-page-image" {
  value = data.aws_ecr_image.landing-page-image.image_digest
}

// ECS

resource "aws_ecs_task_definition" "landing-page-task" {
  family       = "landing-page"
  network_mode = "awsvpc"
  requires_compatibilities = [
  "FARGATE"]
  cpu                = 256
  memory             = 512
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "landing-page"
      image     = "${data.aws_ecr_repository.landing-page-repo.repository_url}:${data.aws_ecr_image.landing-page-image.image_tag}@${data.aws_ecr_image.landing-page-image.image_digest}"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/landing-page"
          awslogs-region        = module.global_vars.region[var.region]
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    "Name"        = "landing-page-task"
    "Environment" = module.global_vars.environment[var.env]
  }
}

resource "aws_ecs_service" "landing-page-service" {
  name            = "landing-page-service"
  cluster         = aws_ecs_cluster.gateway-cluster.id
  task_definition = aws_ecs_task_definition.landing-page-task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.data.vpc_gateway_subs_private
    assign_public_ip = false
    security_groups  = [aws_security_group.gateway-ecs-sg.id]
  }
  desired_count        = 1
  force_new_deployment = true

  load_balancer {
    target_group_arn = data.aws_lb_target_group.lp-tg.arn
    container_name   = "landing-page"
    container_port   = 8080
  }

  tags = {
    "Name"        = "landing-page"
    "Environment" = module.global_vars.environment[var.env]
  }
}
