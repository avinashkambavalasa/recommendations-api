terraform {
  required_version = "= 1.4.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.16.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.6.3"
    }
  }
}
