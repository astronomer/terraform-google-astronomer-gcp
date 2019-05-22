# Astronomer Module

- This is a platform-agnostic module to deploy Astronomer on kubernetes
- This module is typically called on a bastion deployed by a platform-specific terraform module, e.g. ../aws

## Assumptions:

- Kubernetes API server access (network, authorization)
- ./kubeconfig file in the current working directory
- The following two files need to be present and signed for *.your_base_name (your_base_name here is one of the variables for this module)
- /opt/astronomer_cert/tls.crt
- /opt/astronomer_cert/tls.key

Cluster prereq setup expected after applying one of the cloud-specific terraform modules:

This is currently inteded to be used as a terraform module imported by the other modules in this directory.

## Set up:

Look in ../aws/bastion for a suggestion on the execution environment of this module
