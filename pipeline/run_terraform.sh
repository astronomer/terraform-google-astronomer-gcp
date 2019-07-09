#!/bin/bash

echo $GOOGLE_CREDENTIAL_FILE_CONTENT > /tmp/account.json

set -xe

ls /tmp | grep account

export GOOGLE_APPLICATION_CREDENTIALS='/tmp/account.json'

terraform -v

# unique deployment ID to avoid collisions in CI
# needs to be 32 characters or less and start with letter
DEPLOYMENT_ID=ci$(echo "$DRONE_REPO_NAME$DRONE_BUILD_NUMBER" | md5sum | awk '{print substr($1,0,5)}')
ZONAL='true'

if [ $REGIONAL -eq 1 ]; then
  DEPLOYMENT_ID=regional$DEPLOYMENT_ID
  ZONAL=false
fi

echo $DEPLOYMENT_ID

cp providers.tf.example examples/$EXAMPLE/providers.tf
cp backend.tf.example examples/$EXAMPLE/backend.tf
cd examples/$EXAMPLE
sed -i "s/REPLACE/$DEPLOYMENT_ID/g" backend.tf

terraform init

if [ $DESTROY -eq 1 ]; then
    terraform destroy --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL"
else
    terraform apply --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL"
fi
