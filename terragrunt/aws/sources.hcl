locals {
  # Terragrunt copies the entire terraform/ tree into its cache directory, so relative paths like ../modules resolve correctly inside each stack.
  terraform_root = "${get_terragrunt_dir()}/../../terraform"

  terraform_vpc_source     = "${local.terraform_root}//vpc"
  terraform_project_source = "${local.terraform_root}//project"
}
