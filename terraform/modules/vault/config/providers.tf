# AWS region is sourced from the AWS_REGION / AWS_DEFAULT_REGION env var
# set by team members (aws configure) and CI (configure-aws-credentials action).
provider "aws" {}
