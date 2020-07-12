[![Docker pulls](https://img.shields.io/docker/pulls/hectormolinero/musikcube?label=Docker%20pulls)](https://hub.docker.com/r/hectormolinero/musikcube)
[![GitLab CI](https://img.shields.io/gitlab/pipeline/hectorm/docker-musikcube/master?label=GitLab%20CI)](https://gitlab.com/hectorm/docker-musikcube/pipelines)
[![License](https://img.shields.io/github/license/hectorm/docker-musikcube?label=License)](LICENSE.md)

***

# musikcube on Docker

A Docker image for [musikcube](https://github.com/clangen/musikcube).

## Start as daemon

```sh
docker run --detach \
  --name musikcube \
  --restart on-failure:3 \
  --publish 7905:7905/tcp \
  --publish 7906:7906/tcp \
  --env MUSIKCUBE_SERVER_PASSWORD=musikcube \
  --mount type=volume,src=musikcube-data,dst=/var/lib/musikcube/ \
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
  --mount type=volume,src=musikcube-data,dst=/var/lib/musikcube/ \
  --mount type=bind,src="$XDG_RUNTIME_DIR"/pulse/native,dst=/run/user/1000/pulse/native,ro \
  --mount type=bind,src="$HOME"/Music,dst=/music,ro \
  hectormolinero/musikcube:latest
```

## Environment variables

#### `MUSIKCUBE_SERVER_PASSWORD`
This environment variable sets the remote control password, by default its value is `musikcube`.

#### `MUSIKCUBE_OUTPUT_DRIVER`
This environment variable sets the output sound driver, by default its value is `Null`, since the main purpose of this image is to be used as a daemon.

## License

See the [license](LICENSE.md) file.
