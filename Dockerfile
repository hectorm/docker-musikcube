FROM golang:1-stretch AS build-caddy

ARG CADDY_BRANCH=v0.11.0

# Copy Caddy patches
COPY patches/caddy-* /tmp/patches/

# Build Caddy
RUN go get -u github.com/mholt/caddy \
	&& go get -u github.com/caddyserver/builds \
	&& go get -u github.com/caddyserver/dnsproviders/cloudflare \
	&& cd "${GOPATH}/src/github.com/mholt/caddy/caddy" \
	&& git checkout "${CADDY_BRANCH}" \
	&& git apply -v /tmp/patches/caddy-*.patch \
	&& go run build.go \
	&& ./caddy --version \
	&& ./caddy --plugins \
	&& mv ./caddy /usr/local/bin/caddy

FROM ubuntu:18.04 AS build-musikcube

ARG MUSIKCUBE_BRANCH=0.51.0
ARG MUSIKCUBE_REMOTE=https://github.com/clangen/musikcube.git

# Copy musikcube patches
#COPY patches/musikcube-* /tmp/patches/

# Install musikcube build dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		clang \
		cmake \
		curl \
		git \
		libasound2-dev \
		libboost-atomic1.65-dev \
		libboost-chrono1.65-dev \
		libboost-date-time1.65-dev \
		libboost-filesystem1.65-dev \
		libboost-system1.65-dev \
		libboost-thread1.65-dev \
		libcurl4-openssl-dev \
		libev-dev \
		libfaad-dev \
		libflac-dev \
		libmicrohttpd-dev \
		libmp3lame-dev \
		libncursesw5-dev \
		libogg-dev \
		libpulse-dev \
		libssl-dev \
		libvorbis-dev \
		sqlite3

# Build musikcube
RUN mkdir /tmp/musikcube \
	&& cd /tmp/musikcube \
	&& git clone "${MUSIKCUBE_REMOTE}" --recursive . \
	&& git checkout "${MUSIKCUBE_BRANCH}" \
	&& cmake . \
	&& make -j$(nproc) \
	&& cmake . \
	&& make install

# Create music library db
COPY config/musikcube/1/musik.db.sql /tmp/musik.db.sql
RUN sqlite3 /tmp/musik.db < /tmp/musik.db.sql

FROM ubuntu:18.04

# Install runtime dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		jq \
		libasound2 \
		libboost-atomic1.65.1 \
		libboost-chrono1.65.1 \
		libboost-date-time1.65.1 \
		libboost-filesystem1.65.1 \
		libboost-system1.65.1 \
		libboost-thread1.65.1 \
		libcap2-bin \
		libcurl4 \
		libev4 \
		libfaad2 \
		libflac8 \
		libmicrohttpd12 \
		libmp3lame0 \
		libncursesw5 \
		libogg0 \
		libpulse0 \
		libssl1.1 \
		libvorbis0a \
		libvorbisfile3 \
		locales \
		pulseaudio \
	&& rm -rf /var/lib/apt/lists/*

# Create musikcube group, user and folders
ARG MUSIKCUBE_USER_UID=1000
ARG MUSIKCUBE_USER_GID=1000
RUN groupadd \
		--gid "${MUSIKCUBE_USER_GID}" \
		musikcube \
	&& useradd \
		--uid "${MUSIKCUBE_USER_UID}" \
		--gid musikcube \
		--groups audio \
		--home-dir /home/musikcube \
		musikcube

# Copy Caddy build
COPY --from=build-caddy --chown=root:root /usr/local/bin/caddy /usr/local/bin/caddy

# Copy musikcube build
COPY --from=build-musikcube --chown=root:root /usr/local/bin/musikcube /usr/local/bin/musikcube
COPY --from=build-musikcube --chown=root:root /usr/local/bin/musikcubed /usr/local/bin/musikcubed
COPY --from=build-musikcube --chown=root:root /usr/local/share/musikcube/ /usr/local/share/musikcube/

# Copy PulseAudio client configuration
COPY --chown=root:root config/pulse-client.conf /etc/pulse/client.conf

# Copy Caddy configuration
COPY --chown=musikcube:musikcube config/caddy/ /home/musikcube/.caddy/

# Copy musikcube configuration
COPY --chown=musikcube:musikcube config/musikcube/ /home/musikcube/.musikcube/
COPY --from=build-musikcube --chown=musikcube:musikcube /tmp/musik.db /home/musikcube/.musikcube/1/musik.db

# Copy scripts
COPY --chown=root:root scripts/docker-foreground-cmd /usr/local/bin/docker-foreground-cmd

# Setup locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Give Caddy permission to bind to port 80 and 443
RUN setcap cap_net_bind_service=+ep /usr/local/bin/caddy

ENV USE_MUSIKCUBE_CLIENT=0
ENV MUSIKCUBE_SERVER_PASSWORD=musikcube
ENV MUSIKCUBE_OUTPUT_DRIVER=Null

VOLUME /music/
VOLUME /home/musikcube/.caddy/
VOLUME /home/musikcube/.musikcube/
WORKDIR /home/musikcube/

EXPOSE 7905/tcp 7906/tcp

USER musikcube:musikcube
CMD ["docker-foreground-cmd"]
