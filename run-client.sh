#!/bin/sh

set -eu
export LC_ALL=C

DOCKER=$(command -v docker 2>/dev/null)

IMAGE_REGISTRY=docker.io
IMAGE_NAMESPACE=hectormolinero
IMAGE_PROJECT=musikcube
IMAGE_TAG=latest
IMAGE_NAME=${IMAGE_REGISTRY:?}/${IMAGE_NAMESPACE:?}/${IMAGE_PROJECT:?}:${IMAGE_TAG:?}
CONTAINER_NAME=${IMAGE_PROJECT:?}
VOLUME_NAME=${CONTAINER_NAME:?}-data

imageExists() { [ -n "$("${DOCKER:?}" images -q "${1:?}")" ]; }
containerExists() { "${DOCKER:?}" ps -af name="${1:?}" --format '{{.Names}}' | grep -Fxq "${1:?}"; }
containerIsRunning() { "${DOCKER:?}" ps -f name="${1:?}" --format '{{.Names}}' | grep -Fxq "${1:?}"; }

if ! imageExists "${IMAGE_NAME:?}" && ! imageExists "${IMAGE_NAME#docker.io/}"; then
	>&2 printf '%s\n' "\"${IMAGE_NAME:?}\" image doesn't exist!"
	exit 1
fi

if containerIsRunning "${CONTAINER_NAME:?}"; then
	printf '%s\n' "Stopping \"${CONTAINER_NAME:?}\" container..."
	"${DOCKER:?}" stop "${CONTAINER_NAME:?}" >/dev/null
fi

if containerExists "${CONTAINER_NAME:?}"; then
	printf '%s\n' "Removing \"${CONTAINER_NAME:?}\" container..."
	"${DOCKER:?}" rm "${CONTAINER_NAME:?}" >/dev/null
fi

if [ -d "${HOME:?}/Music" ]; then
	MUSIC_FOLDER="${HOME:?}/Music"
fi

if [ -n "${XDG_RUNTIME_DIR-}" ] && [ -S "${XDG_RUNTIME_DIR:?}/pulse/native" ]; then
	PULSEAUDIO_SOCKET="${XDG_RUNTIME_DIR:?}/pulse/native"
fi

printf '%s\n' "Creating \"${CONTAINER_NAME:?}\" container..."
exec "${DOCKER:?}" run -it --rm \
	--name "${CONTAINER_NAME:?}" \
	--hostname "${CONTAINER_NAME:?}" \
	--log-driver none \
	--publish '7905:7905/tcp' \
	--publish '7906:7906/tcp' \
	--env MUSIKCUBE_OUTPUT_DRIVER='PulseAudio' \
	--mount type=volume,src="${VOLUME_NAME:?}",dst='/var/lib/musikcube/' \
	${MUSIKCUBE_SERVER_PASSWORD:+--env MUSIKCUBE_SERVER_PASSWORD="${MUSIKCUBE_SERVER_PASSWORD:?}"} \
	${MUSIC_FOLDER:+--mount type=bind,src="${MUSIC_FOLDER:?}",dst='/music',ro} \
	${PULSEAUDIO_SOCKET:+ \
		--mount type=bind,src="${PULSEAUDIO_SOCKET:?}",dst='/run/user/1000/pulse/native',ro \
		--env PULSE_SERVER='/run/user/1000/pulse/native' \
	} \
	"${IMAGE_NAME:?}" "$@"
