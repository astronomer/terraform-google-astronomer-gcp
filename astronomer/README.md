Given a kubernetes API server access in the form of a file ./kubeconfig, deploy Astronomer


Cluster prereq setup expected after applying one of the cloud-specific terraform modules:

- 'astronomer' namespace
- DB, secret astro-db-postgresql
- secret astronomer-tls with data tls.crt, tls.key
