# To avoid issues with concurrent updates to the state, we use the new Terraform paraemeter use_lockfile.
# Bucket versioning to setup
terraform {
  backend "s3" {
    bucket       = "dummy-devops-terraform-state-bucket"
    key          = "terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    acl          = "private"
    use_lockfile = true
  }
}
