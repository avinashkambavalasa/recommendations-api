include "root" {
  path = find_in_parent_folders()
}

locals {
  sources = read_terragrunt_config(find_in_parent_folders("sources.hcl"))
}

terraform {
  source = local.sources.locals.terraform_vpc_source
}

inputs = {
  app_env    = basename(get_terragrunt_dir())
  app_region = "us-east-2"

  vpc_cidr = "10.82.0.0/16"

  azs = [
    "us-east-2a",
    "us-east-2b"
  ]

  public_subnet_cidrs = [
    "10.82.1.0/24",
    "10.82.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.82.11.0/24",
    "10.82.12.0/24"
  ]

  database_subnet_cidrs = [
    "10.82.21.0/24",
    "10.82.22.0/24"
  ]

  enable_nat_gateway = false
  single_nat_gateway = true
}
