m4_changequote([[, ]])

m4_ifdef([[CROSS_QEMU]], [[
##################################################
## "qemu-user-static" stage
##################################################

FROM ubuntu:18.04 AS qemu-user-static
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends qemu-user-static
]])

##################################################
## "build-musikcube" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM CROSS_ARCH/ubuntu:18.04]], [[FROM ubuntu:18.04]]) AS build-musikcube
m4_ifdef([[CROSS_QEMU]], [[COPY --from=qemu-user-static CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
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
		libavformat-dev \
		libavutil-dev \
		libboost-atomic1.65-dev \
		libboost-chrono1.65-dev \
		libboost-date-time1.65-dev \
		libboost-filesystem1.65-dev \
		libboost-system1.65-dev \
		libboost-thread1.65-dev \
		libcurl4-openssl-dev \
		libev-dev \
		libmicrohttpd-dev \
		libmp3lame-dev \
		libncursesw5-dev \
		libogg-dev \
		libpulse-dev \
		libssl-dev \
		libswresample-dev \
		libtag1-dev \
		libvorbis-dev \
		sqlite3

# Build musikcube
ARG MUSIKCUBE_TREEISH=0.64.0
ARG MUSIKCUBE_REMOTE=https://github.com/clangen/musikcube.git
RUN mkdir -p /tmp/musikcube/ && cd /tmp/musikcube/ \
	&& git clone "${MUSIKCUBE_REMOTE}" ./ \
	&& git checkout "${MUSIKCUBE_TREEISH}" \
	&& git submodule update --init --recursive
RUN cd /tmp/musikcube/ \
	&& cmake . -DCMAKE_INSTALL_PREFIX=/usr \
	&& make -j"$(nproc)" \
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
ENV MUSIKCUBE_SERVER_PASSWORD=musikcube
ENV MUSIKCUBE_OUTPUT_DRIVER=Null

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		jq \
		libasound2 \
		libavformat57 \
		libavutil55 \
		libboost-atomic1.65.1 \
		libboost-chrono1.65.1 \
		libboost-date-time1.65.1 \
		libboost-filesystem1.65.1 \
		libboost-system1.65.1 \
		libboost-thread1.65.1 \
		libcap2-bin \
		libcurl4 \
		libev4 \
		libmicrohttpd12 \
		libmp3lame0 \
		libncursesw5 \
		libogg0 \
		libpulse0 \
		libssl1.1 \
		libswresample2 \
		libtag1v5 \
		libvorbis0a \
		libvorbisfile3 \
		locales \
		nano \
		pulseaudio \
		runit \
	&& rm -rf /var/lib/apt/lists/*

# Setup locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create users and groups
ARG MUSIKCUBE_USER_UID=1000
ARG MUSIKCUBE_USER_GID=1000
RUN groupadd \
		--gid "${MUSIKCUBE_USER_GID}" \
		musikcube
RUN useradd \
		--uid "${MUSIKCUBE_USER_UID}" \
		--gid "${MUSIKCUBE_USER_GID}" \
		--shell "$(which bash)" \
		--home-dir /home/musikcube/ \
		--create-home \
		musikcube

# Create XDG_CONFIG_HOME subdirectories
RUN cd /home/musikcube/ \
	&& mkdir -p ./.config/caddy/ \
	&& mkdir -p ./.config/musikcube/ \
	&& chown -R musikcube:musikcube ./.config/

# Copy Tini build
m4_define([[TINI_IMAGE_TAG]], m4_ifdef([[CROSS_ARCH]], [[v4-CROSS_ARCH]], [[v4]]))m4_dnl
COPY --from=hectormolinero/tini:TINI_IMAGE_TAG --chown=root:root /usr/bin/tini /usr/bin/tini

# Copy Caddy build
m4_define([[CADDY_IMAGE_TAG]], m4_ifdef([[CROSS_ARCH]], [[v13-CROSS_ARCH]], [[v13]]))m4_dnl
COPY --from=hectormolinero/caddy:CADDY_IMAGE_TAG --chown=root:root /usr/bin/caddy /usr/bin/caddy

# Add capabilities to the Caddy binary
RUN setcap cap_net_bind_service=+ep /usr/bin/caddy

# Copy musikcube build
COPY --from=build-musikcube --chown=root:root /usr/bin/musikcube /usr/bin/musikcube
COPY --from=build-musikcube --chown=root:root /usr/bin/musikcubed /usr/bin/musikcubed
COPY --from=build-musikcube --chown=root:root /usr/share/musikcube/ /usr/share/musikcube/

# Copy PulseAudio client configuration
COPY --chown=root:root config/pulse-client.conf /etc/pulse/client.conf

# Copy Caddy configuration
COPY --chown=musikcube:musikcube config/caddy/ /home/musikcube/.config/caddy/

# Copy musikcube configuration
COPY --chown=musikcube:musikcube config/musikcube/ /home/musikcube/.config/musikcube/
COPY --from=build-musikcube --chown=musikcube:musikcube /tmp/musik.db /home/musikcube/.config/musikcube/1/musik.db

# Copy services
COPY --chown=musikcube:musikcube scripts/service/ /home/musikcube/service/

# Copy scripts
COPY --chown=root:root scripts/bin/ /usr/local/bin/

# Drop root privileges
USER musikcube:musikcube

# Expose ports
## WebSocket server (metadata)
EXPOSE 7905/tcp
## HTTP server (audio)
EXPOSE 7906/tcp

# Don't declare volumes, let the user decide
#VOLUME /home/musikcube/.config/caddy/
#VOLUME /home/musikcube/.config/musikcube/

WORKDIR /home/musikcube/

HEALTHCHECK --start-period=60s --interval=30s --timeout=5s --retries=3 \
	CMD /usr/local/bin/docker-healthcheck-cmd

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/docker-foreground-cmd"]
