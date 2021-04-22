#!/bin/bash

cp providers.tf.example providers.tf
terraform init
terraform fmt -check=true
echo '{
    "type": "service_account",
    "project_id": "[PROJECT-ID]",
    "private_key_id": "[KEY-ID]",
    "private_key": "-----BEGIN PRIVATE KEY-----\n[PRIVATE-KEY]\n-----END PRIVATE KEY-----\n",
    "client_email": "[SERVICE-ACCOUNT-EMAIL]",
    "client_id": "[CLIENT-ID]",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://accounts.google.com/o/oauth2/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/[SERVICE-ACCOUNT-EMAIL]"
}' > ~/account.json

terraform validate -var "deployment_id=validate" -var "dns_managed_zone=validate-fake.com" -var "email=fake@mailinator.com"

for example in $(find examples -maxdepth 1 -mindepth 1 -type d); do
cp providers.tf $example
cd $example
echo $example
terraform init
terraform fmt -check=true
terraform validate -var "deployment_id=citest"
cd -
done

terraform -v
