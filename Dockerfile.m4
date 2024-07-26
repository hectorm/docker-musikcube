m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:24.04]], [[FROM docker.io/ubuntu:24.04]]) AS build

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		cmake \
		curl \
		file \
		git \
		libasound2-dev \
		libavcodec-dev \
		libavformat-dev \
		libavutil-dev \
		libcurl4-openssl-dev \
		libev-dev \
		libgme-dev \
		libmicrohttpd-dev \
		libmp3lame-dev \
		libncurses-dev \
		libogg-dev \
		libopenmpt-dev \
		libpipewire-0.3-dev \
		libpulse-dev \
		libssl-dev \
		libswresample-dev \
		libsystemd-dev \
		libtag1-dev \
		libvorbis-dev \
		patchelf \
		portaudio19-dev \
		sqlite3 \
		tzdata \
	&& rm -rf /var/lib/apt/lists/*

# Build musikcube
ARG MUSIKCUBE_TREEISH=3.0.4
ARG MUSIKCUBE_REMOTE=https://github.com/clangen/musikcube.git
RUN mkdir /tmp/musikcube/
WORKDIR /tmp/musikcube/
RUN git clone "${MUSIKCUBE_REMOTE:?}" ./
RUN git checkout "${MUSIKCUBE_TREEISH:?}"
RUN git submodule update --init --recursive
RUN cmake ./ \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr
RUN make -j"$(nproc)"
RUN make install
RUN file /usr/share/musikcube/musikcube
RUN file /usr/share/musikcube/musikcubed
RUN /usr/share/musikcube/musikcubed --version

# Create musikcube library database
COPY ./config/musikcube/1/musik.db.sql /tmp/musikcube/musik.db.sql
RUN sqlite3 /tmp/musikcube/musik.db < /tmp/musikcube/musik.db.sql

##################################################
## "main" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:24.04]], [[FROM docker.io/ubuntu:24.04]]) AS main

# Environment
ENV MUSIKCUBE_PATH=/var/lib/musikcube/
ENV MUSIKCUBE_SERVER_PASSWORD=musikcube
ENV MUSIKCUBE_OUTPUT_DRIVER=Null

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		jq \
		libasound2t64 \
		libavcodec-extra60 \
		libavformat60 \
		libavutil58 \
		libcurl4t64 \
		libev4t64 \
		libev4t64 \
		libmicrohttpd12t64 \
		libmp3lame0 \
		libncursesw6 \
		libogg0 \
		libopenmpt0t64 \
		libpipewire-0.3-0t64 \
		libportaudio2 \
		libpulse0 \
		libssl3t64 \
		libswresample4 \
		libsystemd0 \
		libtag1v5 \
		libvorbis0a \
		libvorbisfile3 \
		locales \
		nano \
		pulseaudio \
		tzdata \
	&& rm -rf /var/lib/apt/lists/*

# Setup locale
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
RUN printf '%s\n' "${LANG:?} UTF-8" > /etc/locale.gen \
	&& localedef -c -i "${LANG%%.*}" -f UTF-8 "${LANG:?}" ||:

# Setup timezone
ENV TZ=UTC
RUN printf '%s\n' "${TZ:?}" > /etc/timezone \
	&& ln -snf "/usr/share/zoneinfo/${TZ:?}" /etc/localtime

# Create unprivileged user
RUN userdel -rf "$(id -nu 1000)" && useradd -u 1000 -g 0 -s "$(command -v bash)" -m musikcube

# Create $MUSIKCUBE_PATH directory
RUN mkdir -p "${MUSIKCUBE_PATH:?}" /home/musikcube/.config/ \
	&& ln -s "${MUSIKCUBE_PATH:?}" /home/musikcube/.config/musikcube \
	&& chown -R musikcube:root "${MUSIKCUBE_PATH:?}" /home/musikcube/

# Copy musikcube build
COPY --from=build --chown=root:root /usr/bin/musikcube /usr/bin/musikcube
COPY --from=build --chown=root:root /usr/bin/musikcubed /usr/bin/musikcubed
COPY --from=build --chown=root:root /usr/share/musikcube/ /usr/share/musikcube/

# Copy PulseAudio configuration
COPY --chown=root:root ./config/pulse/ /etc/pulse/
RUN find /etc/pulse/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/pulse/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'

# Copy musikcube configuration
COPY --chown=musikcube:root ./config/musikcube/ "${MUSIKCUBE_PATH}"
COPY --from=build --chown=musikcube:root /tmp/musikcube/musik.db "${MUSIKCUBE_PATH}"/1/musik.db
RUN find "${MUSIKCUBE_PATH}" -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find "${MUSIKCUBE_PATH}" -type f -not -perm 0644 -exec chmod 0644 '{}' ';'

# Copy scripts
COPY --chown=root:root ./scripts/bin/ /usr/local/bin/
RUN find /usr/local/bin/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /usr/local/bin/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'

# Drop root privileges
USER musikcube:root

## WebSocket server (metadata)
EXPOSE 7905/tcp
## HTTP server (audio)
EXPOSE 7906/tcp

WORKDIR "${MUSIKCUBE_PATH}"
ENTRYPOINT ["/usr/local/bin/container-init"]
