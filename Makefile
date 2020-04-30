#import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= env.mk
include $(cnf)
CACHE = $(REGISTRY)/$(IMAGE):cache
IMG = $(REGISTRY)/$(IMAGE)
IMG_TAG?=latest

OCTOPRINT_VERSION?= $(shell ./scripts/version.sh "OctoPrint/OctoPrint")

.DEFAULT_GOAL := build

clean:
	podman stop buildkit && docker rm buildkit

install: ./scripts/install.sh
	
binfmt: 
	@podman run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64

prepare: 
	@podman buildx create --use

build:
	@echo '[default]: building local octoprint image with all default options'
	@podman build -t octoprint .


buildx:
	@echo '[buildx]: building image: ${IMG}:${IMG_TAG} for all architectures'
	@podman buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 \
		--cache-from ${CACHE} \
		--cache-to	${CACHE} \
		--build-arg PYTHON_BASE_IMAGE=$(PYTHON_BASE_IMAGE) \
		--build-arg tag=${OCTOPRINT_VERSION} \
		--progress plain -t ${IMG}:${IMG_TAG} .

buildx-push:
	@echo '[buildx]: building and pushing images: ${IMG}:${IMG_TAG} for all supported architectures'
	podman buildx build --push --platform linux/arm64,linux/amd64,linux/arm/v7 \
		--cache-from ${CACHE} \
		--cache-to	${CACHE} \
		--build-arg PYTHON_BASE_IMAGE=$(PYTHON_BASE_IMAGE) \
		--build-arg tag=${OCTOPRINT_VERSION} \
		--progress plain -t ${IMG}:${IMG_TAG} .
