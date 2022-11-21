terraform {
  required_version = ">= 0.13"
  backend "gcs" {}
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.11.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.43.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.43.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }
    spotinst = {
      source  = "spotinst/spotinst"
      version = "~> 1.87.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }
  }
}

provider "google" {
  region  = var.region
  project = var.project_id
}

provider "google-beta" {
  region  = var.region
  project = var.project_id
}

provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

provider "spotinst" {
  token = var.spotinist_token
}
