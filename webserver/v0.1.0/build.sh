#!/bin/bash
set -e
export HCP_PACKER_BUILD_FINGERPRINT=v0.1.0-$(date +%F_%H-%M-%S)

echo ========================================
echo Getting Creds from Doormat
echo ========================================

# AWS
doormat login -v || doormat -r && eval $(doormat aws export --account se_demos_dev)

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
par channels set-iteration webserver dev --fingerprint $HCP_PACKER_BUILD_FINGERPRINT

par channels set-iteration webserver production --fingerprint $HCP_PACKER_BUILD_FINGERPRINT
