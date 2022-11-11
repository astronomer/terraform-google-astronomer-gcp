terraform {
  required_version = ">= 0.13"
  backend "gcs" {}
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
