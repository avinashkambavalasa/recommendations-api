# These are account level inputs - set these per AWS account
locals {
    aws_profile = basename(get_terragrunt_dir()) # must match the AWS cli profile/account folder name
}