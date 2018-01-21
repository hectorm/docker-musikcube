#!/bin/sh

set -eu

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

MUSIKCUBE_PASSWORD="${1:-musikcube}"
MUSIKCUBE_GIT_REPOSITORY='https://github.com/clangen/musikcube.git'
MUSIKCUBE_GIT_LATEST_RELEASE=$(curl -fs 'https://api.github.com/repos/clangen/musikcube/releases/latest' |
	grep -m1 '"tag_name"' | cut -d\" -f4
)

docker build --rm \
	--tag musikcube \
	--build-arg MUSIKCUBE_PASSWORD="${MUSIKCUBE_PASSWORD}" \
	--build-arg MUSIKCUBE_GIT_REPOSITORY="${MUSIKCUBE_GIT_REPOSITORY}" \
	--build-arg MUSIKCUBE_GIT_BRANCH="${MUSIKCUBE_GIT_LATEST_RELEASE}" \
	"${SCRIPT_DIR}"
