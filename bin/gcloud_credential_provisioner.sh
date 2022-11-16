#!/bin/bash

echo "$GCP_TOKEN" >$1

set -xe

if [ ! -f $1 ]; then
  echo "google credential json does not exists"
fi
