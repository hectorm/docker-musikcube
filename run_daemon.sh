#!/bin/sh

set -eu

if [ -d "${HOME}/Music" ]; then
	HOST_MUSIC_FOLDER="${HOME}/Music"
	CONTAINER_MUSIC_FOLDER='/music'
fi

docker rm --force musikcube 2>/dev/null || true
docker run --detach \
	--name musikcube \
	--cpus 1 \
	--memory 128mb \
	--publish 7905:7905/tcp \
	--publish 7906:7906/tcp \
	--restart on-failure:10 \
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
	musikcube
