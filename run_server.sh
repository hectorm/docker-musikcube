#!/bin/sh

set -eu

docker rm --force musikcube 2>/dev/null || true
docker run --tty --detach \
	--name musikcube \
	--publish 7905:7905 \
	--publish 7906:7906 \
	--cpus 1 \
	--memory 128mb \
	--restart unless-stopped \
	--mount type=bind,src="${HOME}/Music",dst='/music',ro \
	musikcube
