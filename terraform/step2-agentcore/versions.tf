terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "hello-mcp-s3-terraform-state-common-ground"
    key          = "step2-agentcore/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Gateway MCP targets support IAM SigV4 signing starting in 6.48.0.
      version = ">= 6.48.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
