#!/bin/bash
set -xe

TERRAFORM="${TERRAFORM:-terraform-0.13.7}"

"${TERRAFORM}" -v

cp providers.tf.example providers.tf

"${TERRAFORM}" init
"${TERRAFORM}" fmt -check=true
"${TERRAFORM}" validate -var "deployment_id=validate" -var "dns_managed_zone=validate-fake.com" -var "email=fake@mailinator.com"

find examples -maxdepth 1 -mindepth 1 -type d | while read -r example ; do
  cp providers.tf "${example}"
  cp versions.tf "${example}"
  (
    cd "${example}"
    echo "${example}"
    "${TERRAFORM}" init
    "${TERRAFORM}" fmt -check=true
    "${TERRAFORM}" validate -var "deployment_id=citest"
  )
done
