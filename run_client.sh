#!/bin/sh

set -eu

if [ -d "${HOME}/Music" ]; then
	HOST_MUSIC_FOLDER="${HOME}/Music"
	CONTAINER_MUSIC_FOLDER='/music'
fi

if [ -S "${XDG_RUNTIME_DIR:-}/pulse/native" ]; then
	HOST_PULSEAUDIO_SOCKET="${XDG_RUNTIME_DIR}/pulse/native"
	CONTAINER_PULSEAUDIO_SOCKET='/run/user/1000/pulse/native'
fi

docker rm --force musikcube 2>/dev/null || true
docker run --tty --interactive --rm \
	--name musikcube \
	--cpus 0.5 \
	--memory 128mb \
	--log-driver none \
	--publish 7905:7905/tcp \
	--publish 7906:7906/tcp \
	--env TERM='xterm-256color' \
	--env USE_MUSIKCUBE_CLIENT=1 \
	--env MUSIKCUBE_OUTPUT_DRIVER='AlsaOut' \
	--mount type=volume,src='musikcube-caddy-data',dst='/home/musikcube/.caddy' \
	--mount type=volume,src='musikcube-app-data',dst='/home/musikcube/.musikcube' \
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
	musikcube
