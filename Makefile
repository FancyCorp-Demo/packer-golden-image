.PHONY terraform base webserver build

default: build

build: terraform base webserver

terraform:
	@echo "========================================"
	@echo "Provisioning TF Resources"
	@echo "========================================"
	cd ./terraform && terraform apply


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
