locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("accounts.hcl"), { inputs = {} })
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), { inputs = {} })

  aws_profile         = local.account_vars.locals.aws_profile
  state_bucket        = local.account_vars.locals.state_bucket
  state_bucket_region = local.account_vars.locals.state_bucket_region
  lock_table          = local.account_vars.locals.lock_table
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = var.app_region
  profile = "${local.aws_profile}"
}
EOF
}

# no profile in backend; local runs use AWS_PROFILE and ci uses oidc role creds
remote_state {
  backend = "s3"
  config = {
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.state_bucket_region
    encrypt        = true
    dynamodb_table = local.lock_table
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(local.account_vars.inputs, local.env_vars.inputs)
