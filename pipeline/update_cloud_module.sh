#!/bin/sh

set -xe

apk add sed
# Install Terraform so we can do 'terraform fmt'
TERRAFORM_VERSION=0.12.4
dir=$(pwd)
mkdir /opt/terraform_install && cd /opt/terraform_install && \
  wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  mv terraform /usr/local/bin/
cd $dir

cd /tmp
eval `ssh-agent`
echo "$DEPLOY_KEY" | ssh-add -
mkdir -p $HOME/.ssh
ssh-keyscan -t rsa github.com >> $HOME/.ssh/known_hosts
git clone git@github.com:astronomer/terraform-google-astronomer-cloud.git
cd terraform-google-astronomer-cloud
ls
sed -i "0,/version\s*=\s*\"[0-9]*\.[0-9]*\.[0-9]*\"/ s//version = \"$DRONE_TAG\"/" main.tf
terraform fmt
git add main.tf
git status
git config --global user.email "steven@astronomer.io"
git config --global user.name "Drone CI"
git commit -m "Drone CI: Update GCP infra module to $DRONE_TAG"
git push origin master
