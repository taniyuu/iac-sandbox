terraform {
  # 本体バージョン指定
  required_version = "~> 1.0"

  required_providers {
    # awsバージョン指定
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10.0"
    }

    # archiveバージョン指定
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }

}
# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-1"
}
provider "archive" {}
