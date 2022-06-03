
terraform {
  required_version = ">= 1.0.2"
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.9.0"
    }
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.2"
    }
    spotinst = {
      source  = "spotinst/spotinst"
      version = "~> 1.27"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.4"
    }
  }
}
