#  you need to create an account then uncomment the following lines until toke DON'T uncomment toke lines
terraform {
  cloud {
    organization = "smart-code"

    workspaces {
      name = "terraform-demo"
    }
  }
}