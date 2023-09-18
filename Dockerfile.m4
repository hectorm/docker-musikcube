m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:22.04]], [[FROM docker.io/ubuntu:22.04]]) AS build
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectorm/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

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
		libavcodec-dev \
		portaudio19-dev \
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
		sqlite3 \
		tzdata \
	&& rm -rf /var/lib/apt/lists/*

# Build musikcube
ARG MUSIKCUBE_TREEISH=3.0.2
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

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:22.04]], [[FROM docker.io/ubuntu:22.04]]) AS main
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectorm/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

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
		libasound2 \
		libavcodec-extra \
		libavformat58 \
		libavutil56 \
		libcurl4 \
		libev4 \
		libgme0 \
		libmicrohttpd12 \
		libmp3lame0 \
		libncursesw6 \
		libogg0 \
		libopenmpt0 \
		libpipewire-0.3-0 \
		libportaudio2 \
		libpulse0 \
		libssl3 \
		libswresample3 \
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

# Create users and groups
ARG MUSIKCUBE_USER_UID=1000
ARG MUSIKCUBE_USER_GID=1000
RUN groupadd \
		--gid "${MUSIKCUBE_USER_GID:?}" \
		musikcube
RUN useradd \
		--uid "${MUSIKCUBE_USER_UID:?}" \
		--gid "${MUSIKCUBE_USER_GID:?}" \
		--shell "$(command -v bash)" \
		--home-dir /home/musikcube/ \
		--create-home \
		musikcube

# Create $MUSIKCUBE_PATH directory
RUN mkdir -p "${MUSIKCUBE_PATH:?}" /home/musikcube/.config/ \
	&& ln -s "${MUSIKCUBE_PATH:?}" /home/musikcube/.config/musikcube \
	&& chown -R musikcube:musikcube "${MUSIKCUBE_PATH:?}" /home/musikcube/

# Copy musikcube build
COPY --from=build --chown=root:root /usr/bin/musikcube /usr/bin/musikcube
COPY --from=build --chown=root:root /usr/bin/musikcubed /usr/bin/musikcubed
COPY --from=build --chown=root:root /usr/share/musikcube/ /usr/share/musikcube/

# Copy PulseAudio configuration
COPY --chown=root:root ./config/pulse/ /etc/pulse/
RUN find /etc/pulse/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/pulse/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'

# Copy musikcube configuration
COPY --chown=musikcube:musikcube ./config/musikcube/ "${MUSIKCUBE_PATH}"
COPY --from=build --chown=musikcube:musikcube /tmp/musikcube/musik.db "${MUSIKCUBE_PATH}"/1/musik.db
RUN find "${MUSIKCUBE_PATH}" -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find "${MUSIKCUBE_PATH}" -type f -not -perm 0644 -exec chmod 0644 '{}' ';'

# Copy scripts
COPY --chown=root:root ./scripts/bin/ /usr/local/bin/
RUN find /usr/local/bin/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /usr/local/bin/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'

# Drop root privileges
USER musikcube:musikcube

## WebSocket server (metadata)
EXPOSE 7905/tcp
## HTTP server (audio)
EXPOSE 7906/tcp

WORKDIR "${MUSIKCUBE_PATH}"
ENTRYPOINT ["/usr/local/bin/container-init"]
