terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62"
    }
  }
}

provider "aws" {
  region = "us-east-2"

  # tag all resources with the name of the team reporting, billing, etc.
  # tag all resources with the repo name so they can be managed, inspected, limited together
  default_tags {
    tags = {
      ManagedVia = "https://github.com/barmorgan/bmsutf-workshop"
      Team = var.team_name
    }
  }
}