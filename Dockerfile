FROM ubuntu:16.04 AS build

# Install dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
	&& apt-get install \
		--assume-yes \
		--no-install-recommends \
		build-essential \
		ca-certificates \
		clang \
		cmake \
		curl \
		git \
		libasound2-dev \
		libboost-atomic1.58-dev \
		libboost-chrono1.58-dev \
		libboost-date-time1.58-dev \
		libboost-filesystem1.58-dev \
		libboost-system1.58-dev \
		libboost-thread1.58-dev \
		libcurl4-openssl-dev \
		libev-dev \
		libfaad-dev \
		libflac-dev \
		libmicrohttpd-dev \
		libmp3lame-dev \
		libncursesw5-dev \
		libogg-dev \
		libpulse-dev \
		libvorbis-dev \
		sqlite3 \
	&& rm -rf /var/lib/apt/lists/*

# Build Caddy
ARG GOLANG_RELEASE_URL=https://dl.google.com/go/go1.10.linux-amd64.tar.gz
COPY patches/caddy-import-plugins.patch /tmp/caddy-import-plugins.patch
RUN mkdir /tmp/goroot /tmp/gopath \
	&& export GOROOT=/tmp/goroot \
	&& export GOPATH=/tmp/gopath \
	&& export PATH="${PATH}:${GOROOT}/bin" \
	&& curl -fsSL "${GOLANG_RELEASE_URL}" | tar xzf - --strip-components=1 -C "${GOROOT}" \
	&& go get -u github.com/mholt/caddy \
	&& go get -u github.com/caddyserver/builds \
	&& go get -u github.com/caddyserver/dnsproviders/cloudflare \
	&& cd "${GOPATH}/src/github.com/mholt/caddy/caddy" \
	&& git apply /tmp/caddy-import-plugins.patch \
	&& go run build.go \
	&& ./caddy --version \
	&& ./caddy --plugins \
	&& mv ./caddy /usr/local/bin/caddy

# Build musikcube
ARG MUSIKCUBE_GIT_REPOSITORY=https://github.com/clangen/musikcube.git
ARG MUSIKCUBE_GIT_BRANCH=master
RUN mkdir /tmp/musikcube \
	&& cd /tmp/musikcube \
	&& git clone "${MUSIKCUBE_GIT_REPOSITORY}" --recursive . \
	&& git checkout "${MUSIKCUBE_GIT_BRANCH}" \
	&& cmake . \
	&& make -j$(nproc) \
	&& cmake . \
	&& make install

# Create music library db
COPY config/musikcube/1/musik.db.sql /tmp/musik.db.sql
RUN sqlite3 /tmp/musik.db < /tmp/musik.db.sql

FROM ubuntu:16.04

# Install dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
	&& apt-get install \
		--assume-yes \
		--no-install-recommends \
		jq \
		libasound2 \
		libboost-atomic1.58.0 \
		libboost-chrono1.58.0 \
		libboost-date-time1.58.0 \
		libboost-filesystem1.58.0 \
		libboost-system1.58.0 \
		libboost-thread1.58.0 \
		libcurl3 \
		libev4 \
		libfaad2 \
		libflac8 \
		libmicrohttpd10 \
		libmp3lame0 \
		libncursesw5 \
		libogg0 \
		libpulse0 \
		libvorbis0a \
		libvorbisfile3 \
		locales \
		pulseaudio \
	&& rm -rf /var/lib/apt/lists/*

# Copy files
COPY config/pulse-client.conf /etc/pulse/client.conf

COPY --from=build /usr/local/bin/caddy /usr/local/bin/caddy

COPY --from=build /usr/local/bin/musikcube /usr/local/bin/musikcube
COPY --from=build /usr/local/bin/musikcubed /usr/local/bin/musikcubed
COPY --from=build /usr/local/share/musikcube/ /usr/local/share/musikcube/

COPY config/musikcube/ /home/musikcube/.musikcube/
COPY --from=build /tmp/musik.db /home/musikcube/.musikcube/1/musik.db

COPY scripts/docker-foreground-cmd /usr/local/bin/docker-foreground-cmd

# Setup locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Give Caddy permission to bind to port 80 and 443
RUN setcap cap_net_bind_service=+ep /usr/local/bin/caddy

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
		musikcube \
	&& mkdir -p \
		/home/musikcube/.caddy \
		/home/musikcube/.musikcube \
	&& chown -R musikcube:musikcube /home/musikcube

ENV USE_MUSIKCUBE_CLIENT=0
ENV MUSIKCUBE_SERVER_PASSWORD=musikcube
ENV MUSIKCUBE_OUTPUT_DRIVER=Null

VOLUME /music
VOLUME /home/musikcube/.caddy
VOLUME /home/musikcube/.musikcube

WORKDIR /home/musikcube

EXPOSE 7905 7906

USER musikcube:musikcube
CMD ["docker-foreground-cmd"]
