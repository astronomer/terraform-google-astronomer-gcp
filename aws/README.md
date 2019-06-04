## Astronomer deployment on EKS

Private cloud deployment: Run Astronomer in our account and peer it to the customer's cloud

## Architecture:

- VPC with two public and two private subnets
- kubernetes is deployed into the private subnets
- bastion host deployed into public subnet, with an ssh whitelist for the caller's IP address
- bastion host is assigned an instance profile with kube admin permissions
- Astronomer is deployed from the bastion host to the private EKS cluster
- Both the private and public kubernetes API is turned on (see 'current limitations', below), but you can manually reconfigure to private-only after running terraform apply, and then everything will be set up as expected.

## Prerequisites:

- git
- ssh, ~/.ssh/id_rsa and id_rsa.pub are present
- terraform
- kubectl 1.12.0
- aws-iam-authenticator
- refining an exact IAM role is a work in progress, but this could be used for a starting point: https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples/eks_test_fixture

## Running it

You need to register or choose an existing public route53 hosted zone before running

```
terraform apply
```

## Current Limitations

- When an EKS cluster is created, the calling IAM user is set as the kubernetes admin. This leads to some trickiness to then authorize the bastion host as admin, because the caller needs access to the kubernetes API. This is why we set the public API on, but it's OK to turn it off after the first run - the bastion will be an authorized admin after the local IAM user updates the kubernetes config map (RBAC concept). We are working for a solution involving either port forwarding through the bastion or forwarding the local IAM user to the bastion just for the config map update somehow.

- This was developed using a public Route53 hosted zone. The security implication is that the private IP (e.g. 10.0.2.4) of the astronomer load balancer will be visible in a public DNS record.

- We did not yet define a least-privilege IAM role to execute this terraform module

