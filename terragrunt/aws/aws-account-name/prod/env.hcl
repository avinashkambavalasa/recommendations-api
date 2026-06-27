# shared prod values
inputs = {
  app_env     = "${basename(get_terragrunt_dir())}"
  app_region  = "us-east-2"
  domain_name = "sampledomain.com"
  zone_id     = "" # leave empty to look it up by domain name

  # values from the vpc stack
  vpc_id             = "vpc-xxxxxxxxxxxxxxxxx"
  private_subnet_ids = ["subnet-private-a", "subnet-private-b"]
  public_subnet_ids  = ["subnet-public-a", "subnet-public-b"]
}
