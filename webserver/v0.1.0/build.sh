#!/bin/bash
set -e
set -o pipefail

export HCP_PACKER_BUILD_FINGERPRINT=v0.1.0-$(date +%F_%H-%M-%S)

echo ========================================
echo Getting Creds from Doormat
echo ========================================

# AWS
doormat login -v || doormat login && eval $(doormat aws export --account aws_lucy.davinhart_test)

# Azure
# Not needed, as we can use the CLI creds



echo
echo ========================================
echo Building image ${HCP_PACKER_BUILD_FINGERPRINT}
echo ========================================
packer init .
packer build -force .



echo
echo ========================================
echo Updating HCP Packer Channel
echo ========================================
# TODO: remove the dev channel, as we already have a "latest" channel
par channels set-iteration webserver dev --fingerprint $HCP_PACKER_BUILD_FINGERPRINT

par channels set-iteration webserver production --fingerprint $HCP_PACKER_BUILD_FINGERPRINT
