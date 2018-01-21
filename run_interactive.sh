#!/bin/sh

set -eu

if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
	XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

docker rm --force musikcube 2>/dev/null || true
docker run --tty --interactive --rm \
	--name musikcube \
	--publish 7905:7905 \
	--publish 7906:7906 \
	--cpus 1 \
	--memory 128mb \
	--mount type=bind,src="${HOME}/Music",dst='/music',ro \
	--mount type=bind,src="${XDG_RUNTIME_DIR}/pulse/native",dst='/run/user/1000/pulse/native',ro \
	--env PULSE_SERVER=unix:"${XDG_RUNTIME_DIR}/pulse/native" \
	musikcube \
	"${@:-musikcube}"
