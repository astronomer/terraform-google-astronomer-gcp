#!/bin/bash

echo "$GCP_TOKEN" >/tmp/account.json

set -xe

if [ ! -f /tmp/account.json ]; then
  echo "google credential json does not exists"
fi
