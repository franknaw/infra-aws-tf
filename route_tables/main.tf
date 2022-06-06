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
  Data Source for Development Route Tables
*/
module "data_routes" {
  source = "../../infra-aws-module-tf/data_routes"
}

/*
  Gateway - Route Tables
*/
module "gateway-route-tables" {
  source = "../../infra-aws-module-tf/networking/route_tables"

  name        = module.global_vars.tags["gateway_name"]
  deployment  = module.global_vars.tags["gateway_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  vpc_id = module.data.vpc_gateway.id

  # Configure routes for Private Route Table (Optional)
  private_routes = [

    ###################################################################################
    {
      # Peering rule Gateway to RANGE
      cidr_block                = module.data.vpc_range.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule Gateway to RANGE Private Sub 1
      cidr_block                = module.data.vpc_range_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule Gateway to RANGE Private Sub 2
      cidr_block                = module.data.vpc_range_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule Gateway to RANGE Public Sub 1
      cidr_block                = module.data.vpc_range_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },

    ###################################################################################
    {
      # Peering rule Gateway to GUAC
      cidr_block                = module.data.vpc_guac.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },
    {
      # Peering rule Gateway to GUAC Private Sub 1
      cidr_block                = module.data.vpc_guac_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },
    {
      # Peering rule Gateway to GUAC Private Sub 2
      cidr_block                = module.data.vpc_guac_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },
    {
      # Peering rule Gateway to GUAC Public Sub 1
      cidr_block                = module.data.vpc_guac_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    ###################################################################################
    {
      # Peering rule allow NAT Gateway
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = module.data_routes.nat_gateway_gateway.id
    }
  ]

  # Configure routes for Public Route Table (Optional)
  public_routes = [
    ###################################################################################
    {
      # Peering rule Gateway to RANGE
      cidr_block                = module.data.vpc_range.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule Gateway to RANGE Private Sub 1
      cidr_block                = module.data.vpc_range_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule Gateway to RANGE Private Sub 2
      cidr_block                = module.data.vpc_range_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule Gateway to RANGE Public Sub 1
      cidr_block                = module.data.vpc_range_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },

    ###################################################################################
    {
      # Peering rule Gateway to GUAC
      cidr_block                = module.data.vpc_guac.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },
    {
      # Peering rule Gateway to GUAC Private Sub 1
      cidr_block                = module.data.vpc_guac_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },
    {
      # Peering rule Gateway to GUAC Private Sub 2
      cidr_block                = module.data.vpc_guac_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },
    {
      # Peering rule Gateway to GUAC Public Sub 1
      cidr_block                = module.data.vpc_guac_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    {
      # Peering rule allow Internet Gateway
      cidr_block = "0.0.0.0/0"
      gateway_id = module.data_routes.internet_gateway_gateway.id
    }
  ]
}

// This puts the route table in a cyclic change state
//module "gateway-lms-route-tables-routes-peering" {
//  source = "../../../modules/networking/route_tables_route_peering"
//
//  private_route_table_id = module.gateway-route-tables.route_table_private_id
//  private_subnet_cidr = module.data.vpc_lms_subs_private_cidr_blocks
//  public_route_table_id = module.gateway-route-tables.route_table_public_id
//  public_subnet_cidr = module.data.vpc_lms_subs_public_cidr_blocks
//  vpc_peering_id = module.data_routes.vpc_peering_connection_gateway_lms.id
//}

/*
  Gateway - Route Table Associations
*/
module "gateway-route-table-assoc" {
  source = "../../infra-aws-module-tf/networking/route_tables_assoc"

  private_route_table_id = module.gateway-route-tables.route_table_private_id
  private_subnet_ids     = module.data.vpc_gateway_subs_private
  public_route_table_id  = module.gateway-route-tables.route_table_public_id
  public_subnet_ids      = module.data.vpc_gateway_subs_public
}

/*
  RANGE - Route Tables
*/
module "range-route-tables" {
  source = "../../infra-aws-module-tf/networking/route_tables"

  name        = module.global_vars.tags["range_name"]
  deployment  = module.global_vars.tags["range_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  vpc_id = module.data.vpc_range.id

  private_routes = [

    ###################################################################################
    {
      # Peering rule RANGE to GATEWAY
      cidr_block                = module.data.vpc_gateway.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule RANGE to GATEWAY Private Sub 1
      cidr_block                = module.data.vpc_gateway_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule RANGE to GATEWAY Private Sub 2
      cidr_block                = module.data.vpc_gateway_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule RANGE to GATEWAY Public Sub 1
      cidr_block                = module.data.vpc_gateway_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule RANGE to GATEWAY Public Sub 2
      cidr_block                = module.data.vpc_gateway_subs_public_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },

    {
      # Peering rule RANGE to GUAC
      cidr_block                = module.data.vpc_guac.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule RANGE to GUAC Private Sub 1
      cidr_block                = module.data.vpc_guac_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule RANGE to GUAC Private Sub 2
      cidr_block                = module.data.vpc_guac_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule RANGE to GUAC Public Sub 1
      cidr_block                = module.data.vpc_guac_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },


    {
      # Peering rule allow NAT Gateway
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = module.data_routes.nat_gateway_range.id
    }

  ]

  public_routes = [


    ###################################################################################
    {
      # Peering rule RANGE to GATEWAY
      cidr_block                = module.data.vpc_gateway.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule RANGE to GATEWAY Private Sub 1
      cidr_block                = module.data.vpc_gateway_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule RANGE to GATEWAY Private Sub 2
      cidr_block                = module.data.vpc_gateway_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule RANGE to GATEWAY Public Sub 1
      cidr_block                = module.data.vpc_gateway_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },
    {
      # Peering rule RANGE to GATEWAY Public Sub 2
      cidr_block                = module.data.vpc_gateway_subs_public_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_range.id
    },

    {
      # Peering rule RANGE to GUAC
      cidr_block                = module.data.vpc_guac.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule RANGE to GUAC Private Sub 1
      cidr_block                = module.data.vpc_guac_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule RANGE to GUAC Private Sub 2
      cidr_block                = module.data.vpc_guac_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule RANGE to GUAC Public Sub 1
      cidr_block                = module.data.vpc_guac_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },

    {
      # Peering rule allow Internet Gateway
      cidr_block = "0.0.0.0/0"
      gateway_id = module.data_routes.internet_gateway_range.id
    }

  ]
}

/*
  RANGE - Route Table Associations
*/
module "range-route-table-assoc" {
  source = "../../infra-aws-module-tf/networking/route_tables_assoc"

  private_route_table_id = module.range-route-tables.route_table_private_id
  private_subnet_ids     = module.data.vpc_range_subs_private

  public_route_table_id = module.range-route-tables.route_table_public_id
  public_subnet_ids     = module.data.vpc_range_subs_public
}


/*
  GUAC - Route Tables
*/
module "guac-route-tables" {
  source = "../../infra-aws-module-tf/networking/route_tables"

  name        = module.global_vars.tags["guac_name"]
  deployment  = module.global_vars.tags["guac_deployment"]
  environment = module.global_vars.environment[var.env]
  subsystem   = module.global_vars.tags["subsystem"]

  vpc_id = module.data.vpc_guac.id

  # Configure routes for Private Route Table (Optional)
  private_routes = [

    ###################################################################################
    {
      # Peering rule GUAC to GATEWAY
      cidr_block                = module.data.vpc_gateway.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    {
      # Peering rule GUAC to GATEWAY Private Sub 1
      cidr_block                = module.data.vpc_gateway_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },
    {
      # Peering rule GUAC to GATEWAY Private Sub 2
      cidr_block                = module.data.vpc_gateway_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    {
      # Peering rule GUAC to GATEWAY Public Sub 1
      cidr_block                = module.data.vpc_gateway_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    {
      # Peering rule GUAC to GATEWAY Public Sub 2
      cidr_block                = module.data.vpc_gateway_subs_public_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    ###################################################################################
    {
      # Peering rule GUAC to RANGE
      cidr_block                = module.data.vpc_range.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule GUAC to RANGE Private Sub 1
      cidr_block                = module.data.vpc_range_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule GUAC to RANGE Private Sub 2
      cidr_block                = module.data.vpc_range_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule GUAC to RANGE Public Sub 1
      cidr_block                = module.data.vpc_range_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },

    ###################################################################################

    {
      # Peering rule allow NAT Gateway
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = module.data_routes.nat_gateway_guac.id
    }
  ]

  # Configure routes for Public Route Table (Optional)
  public_routes = [

    ###################################################################################
    {
      # Peering rule GUAC to GATEWAY
      cidr_block                = module.data.vpc_gateway.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    {
      # Peering rule GUAC to GATEWAY Private Sub 1
      cidr_block                = module.data.vpc_gateway_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },
    {
      # Peering rule GUAC to GATEWAY Private Sub 2
      cidr_block                = module.data.vpc_gateway_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    {
      # Peering rule GUAC to GATEWAY Public Sub 1
      cidr_block                = module.data.vpc_gateway_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    {
      # Peering rule GUAC to GATEWAY Public Sub 2
      cidr_block                = module.data.vpc_gateway_subs_public_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_gateway_guac.id
    },

    ###################################################################################
    {
      # Peering rule GUAC to RANGE
      cidr_block                = module.data.vpc_range.cidr_block
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule GUAC to RANGE Private Sub 1
      cidr_block                = module.data.vpc_range_subs_private_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule GUAC to RANGE Private Sub 2
      cidr_block                = module.data.vpc_range_subs_private_cidr_blocks[1]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },
    {
      # Peering rule GUAC to RANGE Public Sub 1
      cidr_block                = module.data.vpc_range_subs_public_cidr_blocks[0]
      vpc_peering_connection_id = module.data_routes.vpc_peering_connection_range_guac.id
    },

    ###################################################################################

    {
      # Peering rule allow Internet Gateway
      cidr_block = "0.0.0.0/0"
      gateway_id = module.data_routes.internet_gateway_guac.id
    }
  ]
}

/*
  GUAC - Route Table Associations
*/
module "guac-route-table-assoc" {
  source = "../../infra-aws-module-tf/networking/route_tables_assoc"

  private_route_table_id = module.guac-route-tables.route_table_private_id
  private_subnet_ids     = module.data.vpc_guac_subs_private

  public_route_table_id = module.guac-route-tables.route_table_public_id
  public_subnet_ids     = module.data.vpc_guac_subs_public
}
