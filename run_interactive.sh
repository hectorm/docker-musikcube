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
	--cpus 1 \
	--memory 128mb \
	--publish 7905:7905 \
	--publish 7906:7906 \
	--env MUSIKCUBE_INTERACTIVE=1 \
	${HOST_MUSIC_FOLDER:+ \
		--mount type=bind,src="${HOST_MUSIC_FOLDER}",dst="${CONTAINER_MUSIC_FOLDER}",ro \
	} \
	${HOST_PULSEAUDIO_SOCKET:+ \
		--mount type=bind,src="${HOST_PULSEAUDIO_SOCKET}",dst="${CONTAINER_PULSEAUDIO_SOCKET}",ro \
		--env PULSE_SERVER="${CONTAINER_PULSEAUDIO_SOCKET}" \
	} \
	musikcube
