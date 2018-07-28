#!/bin/sh

set -eu
export LC_ALL=C

DOCKER_IMAGE=hectormolinero/musikcube:latest
DOCKER_CONTAINER=musikcube
DOCKER_CADDY_VOLUME="${DOCKER_CONTAINER}"-caddy-data
DOCKER_APP_VOLUME="${DOCKER_CONTAINER}"-app-data

imageExists() { [ -n "$(docker images -q "$1")" ]; }
containerExists() { docker ps -aqf name="$1" --format '{{.Names}}' | grep -Fxq "$1"; }
containerIsRunning() { docker ps -qf name="$1" --format '{{.Names}}' | grep -Fxq "$1"; }

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

if [ -S "${XDG_RUNTIME_DIR:-}/pulse/native" ]; then
	HOST_PULSEAUDIO_SOCKET="${XDG_RUNTIME_DIR}/pulse/native"
	CONTAINER_PULSEAUDIO_SOCKET='/run/user/1000/pulse/native'
fi

printf -- '%s\n' "Creating \"${DOCKER_CONTAINER}\" container..."
exec docker run --tty --interactive --rm \
	--name "${DOCKER_CONTAINER}" \
	--hostname "${DOCKER_CONTAINER}" \
	--log-driver none \
	--publish '7905:7905/tcp' \
	--publish '7906:7906/tcp' \
	--env TERM='xterm-256color' \
	--env USE_MUSIKCUBE_CLIENT=1 \
	--env MUSIKCUBE_OUTPUT_DRIVER='AlsaOut' \
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
	${HOST_PULSEAUDIO_SOCKET:+ \
		--mount type=bind,src="${HOST_PULSEAUDIO_SOCKET}",dst="${CONTAINER_PULSEAUDIO_SOCKET}",ro \
		--env PULSE_SERVER="${CONTAINER_PULSEAUDIO_SOCKET}" \
	} \
	"${DOCKER_IMAGE}" "$@"
