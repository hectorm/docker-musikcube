#!/usr/bin/make -f

MKFILE_RELPATH := $(shell printf -- '%s' '$(MAKEFILE_LIST)' | sed 's|^\ ||')
MKFILE_ABSPATH := $(shell readlink -f -- '$(MKFILE_RELPATH)')
MKFILE_DIR := $(shell dirname -- '$(MKFILE_ABSPATH)')

MUSIKCUBE_GIT_REPOSITORY := https://github.com/clangen/musikcube.git
MUSIKCUBE_GIT_BRANCH := 0.42.0

.PHONY: all \
	build build-image \
	clean clean-image clean-dist

all: build

build: dist/musikcube.tgz

build-image:
	docker build \
		--rm \
		--tag musikcube \
		--build-arg MUSIKCUBE_GIT_REPOSITORY='$(MUSIKCUBE_GIT_REPOSITORY)' \
		--build-arg MUSIKCUBE_GIT_BRANCH='$(MUSIKCUBE_GIT_BRANCH)' \
		'$(MKFILE_DIR)'

dist/:
	mkdir -p dist

dist/musikcube.tgz: dist/ build-image
	docker save musikcube | gzip > dist/musikcube.tgz

clean: clean-image clean-dist

clean-image:
	-docker rmi musikcube

clean-dist:
	rm -f dist/musikcube.tgz
	-rmdir dist
