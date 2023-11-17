#!/bin/bash
set -e
set -o pipefail

if [[ "$1" == "--no-channel" ]]; then
	echo Starting a no-channel build...
fi

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
packer init -upgrade .
packer build -force .



# If we want to build without assigning to a channel...
# i.e. if we want to have a newer version of the image we can upgrade to
if [[ "$1" == "--no-channel" ]]; then
	echo
	echo ========================================
	echo Skipping HCP Packer Channel Assignment
	echo ========================================

	exit 0
fi


echo
echo ========================================
echo Updating HCP Packer Channel
echo ========================================

# This is where you'd do validation before promoting...



# Get iteration ID from `latest` channel, and set to Prod
iteration_id=$(par channels get-iteration webserver latest)

par channels set-iteration webserver production ${iteration_id}
