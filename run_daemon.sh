#!/bin/sh

set -eu
export LC_ALL=C

DOCKER_IMAGE=musikcube:latest
DOCKER_CONTAINER=musikcube
DOCKER_CADDY_VOLUME="${DOCKER_CONTAINER}"-caddy-data
DOCKER_APP_VOLUME="${DOCKER_CONTAINER}"-app-data

imageExists() { [ -n "$(docker images -q "$1")" ]; }
containerExists() { docker ps -aqf name="$1" --format '{{.Names}}' | grep -qw "$1"; }
containerIsRunning() { docker ps -qf name="$1" --format '{{.Names}}' | grep -qw "$1"; }

if ! imageExists "${DOCKER_IMAGE}"; then
	>&2 printf -- '%s\n' "${DOCKER_IMAGE} image doesn't exist!"
	exit 1
fi

if containerIsRunning "${DOCKER_CONTAINER}"; then
	printf -- '%s\n' "Stopping \"${DOCKER_CONTAINER}\" container..."
	docker stop "${DOCKER_CONTAINER}" >/dev/null
fi

if containerExists "${DOCKER_CONTAINER}"; then
	printf -- '%s\n' "Removing \"${DOCKER_CONTAINER}\" container..."
	docker rm "${DOCKER_CONTAINER}" >/dev/null
fi

if [ -d "${HOME}/Music" ]; then
	HOST_MUSIC_FOLDER="${HOME}/Music"
	CONTAINER_MUSIC_FOLDER='/music'
fi

printf -- '%s\n' "Creating \"${DOCKER_CONTAINER}\" container..."
exec docker run --detach \
	--name "${DOCKER_CONTAINER}" \
	--hostname "${DOCKER_CONTAINER}" \
	--cpus 0.5 \
	--memory 128mb \
	--restart on-failure:3 \
	--log-opt max-size=100m \
	--publish '7905:7905/tcp' \
	--publish '7906:7906/tcp' \
	--mount type=volume,src="${DOCKER_CADDY_VOLUME}",dst='/home/musikcube/.caddy' \
	--mount type=volume,src="${DOCKER_APP_VOLUME}",dst='/home/musikcube/.musikcube' \
	${MUSIKCUBE_SERVER_PASSWORD:+ \
		--env MUSIKCUBE_SERVER_PASSWORD="${MUSIKCUBE_SERVER_PASSWORD}" \
	} \
	${CLOUDFLARE_EMAIL:+ \
		--env CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL}" \
	} \
	${CLOUDFLARE_API_KEY:+ \
		--env CLOUDFLARE_API_KEY="${CLOUDFLARE_API_KEY}" \
	} \
	${HOST_MUSIC_FOLDER:+ \
		--mount type=bind,src="${HOST_MUSIC_FOLDER}",dst="${CONTAINER_MUSIC_FOLDER}",ro \
	} \
	"${DOCKER_IMAGE}" "$@"
