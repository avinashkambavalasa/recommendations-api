terraform {
  required_version = "= 1.4.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.6.3"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "= 2.7.1"
    }
  }
}
