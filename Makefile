#!/usr/bin/make -f

MKFILE_RELPATH := $(shell printf -- '%s' '$(MAKEFILE_LIST)' | sed 's|^\ ||')
MKFILE_ABSPATH := $(shell readlink -f -- '$(MKFILE_RELPATH)')
MKFILE_DIR := $(shell dirname -- '$(MKFILE_ABSPATH)')

DIST_DIR := $(MKFILE_DIR)/dist

DOCKER_IMAGE_NAMESPACE := hectormolinero
DOCKER_IMAGE_NAME := musikcube
DOCKER_IMAGE_TAG := latest
DOCKER_IMAGE := $(DOCKER_IMAGE_NAMESPACE)/$(DOCKER_IMAGE_NAME)
DOCKER_CONTAINER := $(DOCKER_IMAGE_NAME)
DOCKERFILE := $(MKFILE_DIR)/Dockerfile

.PHONY: all \
	build build-image save-image \
	clean clean-image clean-container clean-dist

all: build

build: save-image

build-image:
	docker build \
		--tag '$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)' \
		--file '$(DOCKERFILE)' \
		-- '$(MKFILE_DIR)'

save-image: build-image
	mkdir -p -- '$(DIST_DIR)'
	docker save -- '$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)' | gzip > '$(DIST_DIR)/$(DOCKER_IMAGE_NAME).$(DOCKER_IMAGE_TAG).tgz'

clean: clean-image clean-dist

clean-image: clean-container
	-docker rmi -- '$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)'

clean-container:
	-docker stop -- '$(DOCKER_CONTAINER)'
	-docker rm -- '$(DOCKER_CONTAINER)'

clean-dist:
	rm -rf -- '$(DIST_DIR)
