terraform {
  required_providers {
    aws = {
      source  = var.provider-source
      version = var.version
    }
  }
  backend "s3" {
    bucket = var.bucket-name
    key    = var.bucket-key
    region = var.region
  }
}

provider "aws" {
  region = var.region
}