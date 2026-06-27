# account level inputs — set these per AWS account
locals {
  aws_profile         = basename(get_terragrunt_dir())   # matches the AWS CLI profile / account folder name
  state_bucket        = "${local.aws_profile}-state"    # S3 bucket must exist before first apply (see bootstrap below)
  state_bucket_region = "us-east-2"
  lock_table          = "terraform-state-lock"           # DynamoDB table must exist before first apply
}

inputs = {
  account_name = local.aws_profile

  common_tags = {
    owner      = "sample-team"
    managed_by = "terraform"
    account    = local.aws_profile
  }
}