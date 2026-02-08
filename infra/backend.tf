terraform {
  backend "s3" {
    bucket       = "uniplus-rep-g5"
    key          = "aws-uniplus/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}