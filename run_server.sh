#!/bin/sh

set -eu

if [ -d "${HOME}/Music" ]; then
	HOST_MUSIC_FOLDER="${HOME}/Music"
	CONTAINER_MUSIC_FOLDER='/music'
fi

docker rm --force musikcube 2>/dev/null || true
docker run --tty --detach \
	--name musikcube \
	--cpus 1 \
	--memory 128mb \
	--publish 7905:7905 \
	--publish 7906:7906 \
	--restart on-failure:10 \
	--env CLOUDFLARE_EMAIL='email@example.com' \
	--env CLOUDFLARE_API_KEY='xxxxxxxxxxxxxxx' \
	${HOST_MUSIC_FOLDER:+ \
		--mount type=bind,src="${HOST_MUSIC_FOLDER}",dst="${CONTAINER_MUSIC_FOLDER}",ro \
	} \
	musikcube
