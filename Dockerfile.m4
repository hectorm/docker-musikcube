m4_changequote([[, ]])

m4_ifdef([[CROSS_QEMU]], [[
##################################################
## "qemu-user-static" stage
##################################################

FROM ubuntu:18.04 AS qemu-user-static
RUN DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends qemu-user-static
]])

##################################################
## "build-caddy" stage
##################################################

FROM golang:1-stretch AS build-caddy

# Install system packages
RUN DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		file

# Copy Caddy patches
COPY patches/caddy-* /tmp/patches/

# Build Caddy
ARG CADDY_TREEISH=v0.11.1
RUN go get -v -d github.com/mholt/caddy \
	&& cd "${GOPATH}/src/github.com/mholt/caddy/caddy" \
	&& git checkout "${CADDY_TREEISH}"
RUN go get -v -d github.com/caddyserver/builds
RUN go get -v -d github.com/xenolf/lego/providers/dns/cloudflare \
	&& cd "${GOPATH}/src/github.com/xenolf/lego/providers/dns/cloudflare" \
	&& git checkout 'b05b54d1f69a31ceed92e2995243c5b17821c9e4'
RUN go get -v -d github.com/caddyserver/dnsproviders/cloudflare \
	&& cd "${GOPATH}/src/github.com/caddyserver/dnsproviders/cloudflare" \
	&& git checkout '73747960ab3d77b4b4413d3d12433e04cc2663bf'
RUN cd "${GOPATH}/src/github.com/mholt/caddy/caddy" \
	&& git apply -v /tmp/patches/caddy-*.patch \
	&& export GOOS=m4_ifdef([[CROSS_GOOS]], [[CROSS_GOOS]]) \
	&& export GOARCH=m4_ifdef([[CROSS_GOARCH]], [[CROSS_GOARCH]]) \
	&& export GOARM=m4_ifdef([[CROSS_GOARM]], [[CROSS_GOARM]]) \
	&& go build -o ./caddy ./main.go \
	&& file ./caddy \
	&& mv ./caddy /usr/bin/caddy

##################################################
## "build-musikcube" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM CROSS_ARCH/ubuntu:18.04]], [[FROM ubuntu:18.04]]) AS build-musikcube
m4_ifdef([[CROSS_QEMU]], [[COPY --from=qemu-user-static CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		clang \
		cmake \
		curl \
		file \
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
ARG MUSIKCUBE_TREEISH=0.51.0
ARG MUSIKCUBE_REMOTE=https://github.com/clangen/musikcube.git
RUN mkdir -p /tmp/musikcube/ && cd /tmp/musikcube/ \
	&& git clone --recursive "${MUSIKCUBE_REMOTE}" ./ \
	&& git checkout "${MUSIKCUBE_TREEISH}"
RUN cd /tmp/musikcube/ \
	&& cmake . -DCMAKE_INSTALL_PREFIX=/usr \
	&& make -j$(nproc) \
	&& make install \
	&& file /usr/share/musikcube/musikcube \
	&& file /usr/share/musikcube/musikcubed

# Create music library db
COPY config/musikcube/1/musik.db.sql /tmp/musik.db.sql
RUN sqlite3 /tmp/musik.db < /tmp/musik.db.sql

##################################################
## "musikcube" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM CROSS_ARCH/ubuntu:18.04]], [[FROM ubuntu:18.04]]) AS musikcube
m4_ifdef([[CROSS_QEMU]], [[COPY --from=qemu-user-static CROSS_QEMU CROSS_QEMU]])

# Environment
ENV USE_MUSIKCUBE_CLIENT=0
ENV MUSIKCUBE_SERVER_PASSWORD=musikcube
ENV MUSIKCUBE_OUTPUT_DRIVER=Null

# Install system packages
RUN DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
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
		nano \
		pulseaudio \
	&& rm -rf /var/lib/apt/lists/*

# Create users and groups
ARG MUSIKCUBE_USER_UID=1000
ARG MUSIKCUBE_USER_GID=1000
RUN groupadd \
		--gid "${MUSIKCUBE_USER_GID}" \
		musikcube
RUN useradd \
		--uid "${MUSIKCUBE_USER_UID}" \
		--gid "${MUSIKCUBE_USER_GID}" \
		--shell="$(which bash)" \
		--home-dir /home/musikcube/ \
		--create-home \
		musikcube

# Copy Caddy build
COPY --from=build-caddy --chown=root:root /usr/bin/caddy /usr/bin/caddy

# Copy musikcube build
COPY --from=build-musikcube --chown=root:root /usr/bin/musikcube /usr/bin/musikcube
COPY --from=build-musikcube --chown=root:root /usr/bin/musikcubed /usr/bin/musikcubed
COPY --from=build-musikcube --chown=root:root /usr/share/musikcube/ /usr/share/musikcube/

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

# Add capabilities to the caddy binary
RUN setcap cap_net_bind_service=+ep /usr/bin/caddy

# Drop root privileges
USER musikcube:musikcube

# Expose ports
## WebSocket server (metadata)
EXPOSE 7905/tcp
## HTTP server (audio)
EXPOSE 7906/tcp

# Don't declare volumes, let the user decide
#VOLUME /music/
#VOLUME /home/musikcube/.caddy/
#VOLUME /home/musikcube/.musikcube/

WORKDIR /home/musikcube/

CMD ["/usr/local/bin/docker-foreground-cmd"]
