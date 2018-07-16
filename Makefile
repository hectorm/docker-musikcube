#!/usr/bin/make -f

MKFILE_RELPATH := $(shell printf -- '%s' '$(MAKEFILE_LIST)' | sed 's|^\ ||')
MKFILE_ABSPATH := $(shell readlink -f -- '$(MKFILE_RELPATH)')
MKFILE_DIR := $(shell dirname -- '$(MKFILE_ABSPATH)')

CADDY_BRANCH := v0.11.0
MUSIKCUBE_BRANCH := 0.50.0

DIST_DIR := $(MKFILE_DIR)/dist

DOCKER_IMAGE_NAMESPACE := hectormolinero
DOCKER_IMAGE_NAME := musikcube
DOCKER_IMAGE_TARBALL := $(DIST_DIR)/$(DOCKER_IMAGE_NAME).tgz
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
		--tag '$(DOCKER_IMAGE):latest' \
		--tag '$(DOCKER_IMAGE):$(MUSIKCUBE_BRANCH)' \
		--build-arg CADDY_BRANCH='$(CADDY_BRANCH)' \
		--build-arg MUSIKCUBE_BRANCH='$(MUSIKCUBE_BRANCH)' \
		--file '$(DOCKERFILE)' \
		-- '$(MKFILE_DIR)'

save-image: build-image
	mkdir -p -- '$(DIST_DIR)'
	docker save -- '$(DOCKER_IMAGE)' | gzip > '$(DOCKER_IMAGE_TARBALL)'

clean: clean-image clean-dist

clean-image: clean-container
	-docker rmi -- '$(DOCKER_IMAGE)'

clean-container:
	-docker stop -- '$(DOCKER_CONTAINER)'
	-docker rm -- '$(DOCKER_CONTAINER)'

clean-dist:
	rm -f -- '$(DOCKER_IMAGE_TARBALL)'
	-rmdir -- '$(DIST_DIR)'
