#!/bin/bash

TERRAFORM="${TERRAFORM:-terraform}"

"${TERRAFORM}" -v

echo "$GCP_TOKEN" > /tmp/account.json

set -xe

if [ ! -f /tmp/account.json ]; then
  echo "google credential json does not exists"
fi


export GOOGLE_APPLICATION_CREDENTIALS='/tmp/account.json'


# unique deployment ID to avoid collisions in CI
# needs to be 32 characters or less and start with letter
DEPLOYMENT_ID=ci$(echo "${CIRCLE_PROJECT_REPONAME}${CIRCLE_SHA1}" | md5sum | awk '{print substr($1,0,5)}')
ZONAL='true'

if [[ "$REGIONAL" -eq 1 ]]; then
  DEPLOYMENT_ID=regional$DEPLOYMENT_ID
  ZONAL=false
fi

echo "$DEPLOYMENT_ID"

cp providers.tf.example "examples/$EXAMPLE/providers.tf"
cp backend.tf.example "examples/$EXAMPLE/backend.tf"
cp versions.tf "examples/$EXAMPLE/versions.tf"
cd "examples/$EXAMPLE"
sed -i "s/REPLACE/$DEPLOYMENT_ID/g" backend.tf

"${TERRAFORM}" init

if [[ "$DESTROY" -eq 1 ]]; then
    "${TERRAFORM}" destroy --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -lock=false -refresh=false
else
    # this helps to fail fast in the pipeline, but it's not necessary
    "${TERRAFORM}" apply --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -lock=false --target=module.astronomer_gcp.google_service_networking_connection.private_vpc_connection
    "${TERRAFORM}" apply --auto-approve -var "deployment_id=$DEPLOYMENT_ID" -var "zonal=$ZONAL" -lock=false
fi
