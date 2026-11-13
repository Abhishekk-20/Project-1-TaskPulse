terraform {
  backend "s3" {
    bucket       = "taskpulse-tfstate-18eac11fb4e2"
    key          = "taskpulse/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
