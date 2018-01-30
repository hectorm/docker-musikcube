#!/bin/sh

set -eu

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

MUSIKCUBE_GIT_REPOSITORY='https://github.com/clangen/musikcube.git'
MUSIKCUBE_GIT_BRANCH=${1:-$(curl -fs 'https://api.github.com/repos/clangen/musikcube/releases/latest' |
	grep -m1 '"tag_name"' | cut -d\" -f4
)}

printf -- 'Building "%s" from "%s"...\n' "${MUSIKCUBE_GIT_LATEST_RELEASE}" "${MUSIKCUBE_GIT_REPOSITORY}"

docker build --rm \
	--tag musikcube \
	--build-arg MUSIKCUBE_GIT_REPOSITORY="${MUSIKCUBE_GIT_REPOSITORY}" \
	--build-arg MUSIKCUBE_GIT_BRANCH="${MUSIKCUBE_GIT_BRANCH}" \
	"${SCRIPT_DIR}"
