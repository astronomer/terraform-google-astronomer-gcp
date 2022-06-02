
terraform {
  required_version = ">= 1.1.9"
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "2.9.0"
    }
    google = {
      source = "hashicorp/google"
      version = "4.23.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "4.23.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.2.0"
    }
    spotinst = {
      source  = "spotinst/spotinst"
      version = "1.76.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.4.0"
    }
  }
}
