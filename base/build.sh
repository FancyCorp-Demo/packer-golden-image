#!/bin/bash
set -e
set -o pipefail

echo ========================================
echo Getting Creds from Doormat
echo ========================================

# AWS
doormat login -v || doormat login && eval $(doormat aws export --account aws_lucy.davinhart_test)

# Azure
# Not needed, as we can use the CLI creds

export HCP_ORGANIZATION_ID=ffa120a5-d7b1-4b9c-be17-33a71e45f43f
export HCP_PROJECT_ID=d6c96d2b-616b-4cb8-b78c-9e17a78c2167


echo
echo ========================================
echo Building image ${HCP_PACKER_BUILD_FINGERPRINT}
echo ========================================
packer init -upgrade .
packer build -force .



echo
echo ========================================
echo Updating HCP Packer Channel
echo ========================================

# This is where you'd do validation before promoting...



# Get iteration ID from `latest` channel, and set to Prod
iteration_id=$(par channels get-iteration base-image latest)

par channels set-iteration base-image production ${iteration_id}
