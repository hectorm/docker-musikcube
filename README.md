[![Pipeline Status](https://gitlab.com/hectorm/docker-musikcube/badges/master/pipeline.svg)](https://gitlab.com/hectorm/docker-musikcube/pipelines)
[![Docker Image Size](https://img.shields.io/microbadger/image-size/hectormolinero/musikcube/latest.svg)](https://hub.docker.com/r/hectormolinero/musikcube/)
[![Docker Image Layers](https://img.shields.io/microbadger/layers/hectormolinero/musikcube/latest.svg)](https://hub.docker.com/r/hectormolinero/musikcube/)
[![License](https://img.shields.io/github/license/hectorm/docker-musikcube.svg)](LICENSE.md)

***

# musikcube
A Docker image for [musikcube](https://github.com/clangen/musikcube).

## Start as daemon
```sh
docker run --detach \
  --name musikcube \
  --restart on-failure:3 \
  --publish 7905:7905/tcp \
  --publish 7906:7906/tcp \
  --env MUSIKCUBE_SERVER_PASSWORD=musikcube \
  --mount type=volume,src=musikcube-caddy-data,dst=/home/musikcube/.config/caddy \
  --mount type=volume,src=musikcube-app-data,dst=/home/musikcube/.config/musikcube \
  --mount type=bind,src="$HOME"/Music,dst=/music,ro \
  hectormolinero/musikcube:latest
```

## Start as client
```sh
docker run --tty --interactive --rm \
  --name musikcube \
  --log-driver none \
  --publish 7905:7905/tcp \
  --publish 7906:7906/tcp \
  --env MUSIKCUBE_SERVER_PASSWORD=musikcube \
  --env MUSIKCUBE_OUTPUT_DRIVER=PulseAudio \
  --env PULSE_SERVER=/run/user/1000/pulse/native \
  --mount type=volume,src=musikcube-caddy-data,dst=/home/musikcube/.config/caddy \
  --mount type=volume,src=musikcube-app-data,dst=/home/musikcube/.config/musikcube \
  --mount type=bind,src="$XDG_RUNTIME_DIR"/pulse/native,dst=/run/user/1000/pulse/native,ro \
  --mount type=bind,src="$HOME"/Music,dst=/music,ro \
  hectormolinero/musikcube:latest
```

## Environment variables
#### `MUSIKCUBE_SERVER_PASSWORD`
This environment variable sets the remote control password, by default its value is `musikcube`.

#### `MUSIKCUBE_OUTPUT_DRIVER`
This environment variable sets the output sound driver, by default its value is `Null`, since the main purpose of this image is to be used as a daemon.

## Enable TLS with Caddy and Let's Encrypt
This image uses [Caddy web server](https://caddyserver.com/) as a reverse proxy for musikcube, you can enable TLS by modifying the
[`Caddyfile`](https://caddyserver.com/docs/caddyfile) located in `/home/musikcube/.config/caddy/Caddyfile` and following
[the instructions](https://caddyserver.com/docs/tls) in Caddy's documentation.
[All DNS providers are included](https://github.com/hectorm/docker-caddy).

## License
See the [license](LICENSE.md) file.
