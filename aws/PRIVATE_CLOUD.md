## Customers need to:

- Accept the VPC peering request
- For each VPC and private subnet they want to access the platform, they need to add a route to their route table: our vpc's CIDR | vpc peering connection ID

## Troubleshooting:

- If the above doesn't work, check on their security groups that might be in the way, and ask about corporate firewalls / proxies
- There is some issue with Firefox where the certificate is not trusted. This should only happen when Firefox is first installed. Please wait a few minutes for Firefox to update its root CA store.
