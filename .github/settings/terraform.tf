terraform {
  backend "local" {}

  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.2.3"
    }
  }
}
