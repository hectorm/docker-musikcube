#!/bin/sh

set -eu

if [ -d "${HOME}/Music" ]; then
	HOST_MUSIC_FOLDER="${HOME}/Music"
	CONTAINER_MUSIC_FOLDER='/music'
fi

docker stop musikcube 2>/dev/null || true
docker rm musikcube 2>/dev/null || true

exec docker run --detach \
	--name musikcube \
	--cpus 0.5 \
	--memory 128mb \
	--restart on-failure:3 \
	--log-opt max-size=100m \
	--publish 7905:7905/tcp \
	--publish 7906:7906/tcp \
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
