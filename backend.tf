terraform {
  backend "s3" {
    bucket       = "project-1-211125536240-us-east-1-an"
    key          = "project3/vpc/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true 
  }
}