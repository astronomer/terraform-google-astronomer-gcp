
terraform {
  required_version = ">= 0.13"
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 1.4"
    }
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 1.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 1.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.2"
    }
    spotinst = {
      source  = "spotinst/spotinst"
      version = "~> 1.17"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 2.1"
    }
  }
}
