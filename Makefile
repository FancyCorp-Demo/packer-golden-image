.PHONY: terraform base webserver build

default: build

build: terraform base webserver

terraform:
	@echo skipping TF for now
	#@echo "========================================"
	#@echo "Provisioning TF Resources"
	#@echo "========================================"
	#cd ./terraform && terraform init && terraform apply -auto-approve


base:
	@echo "========================================"
	@echo "Building Base Image"
	@echo "========================================"
	cd base && ./build.sh

webserver:
	@echo "========================================"
	@echo "Building Webserver Image"
	@echo "========================================"
	cd webserver/v0.1.0 && ./build.sh

# Build a second time, so we have a newer non-prod image
webserver-no-channel:
	@echo "========================================"
	@echo "Building Webserver Image"
	@echo "========================================"
	cd webserver/v0.1.0 && ./build.sh --no-channel

tfc-dashboard:
	@echo "========================================"
	@echo "Building TFC Dashboard Image"
	@echo "========================================"
	cd images/tfc-dashboard && ./build.sh
