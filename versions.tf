
terraform {
  required_version = ">= 0.13"
  required_providers {
    acme = {
      source  = "vancluever/acme"
    }
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
    http = {
      source  = "hashicorp/http"
    }
    local = {
      source  = "hashicorp/local"
    }
    null = {
      source  = "hashicorp/null"
    }
    random = {
      source  = "hashicorp/random"
    }
    spotinst = {
      source  = "spotinst/spotinst"
    }
    tls = {
      source  = "hashicorp/tls"
    }
  }
}
