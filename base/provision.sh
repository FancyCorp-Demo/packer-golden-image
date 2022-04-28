#!/bin/bash
set -ex

sudo apt-get -yq update
sudo apt-get -yq install software-properties-common
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get -yq update


# Install Vault, for Vault Agent
sudo apt-get -yq install vault

# Install Consul, to register with Service Catalog
sudo apt-get -yq install consul

# A real base image would include some stuff to configure these clients
