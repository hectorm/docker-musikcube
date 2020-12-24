m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:20.04]], [[FROM docker.io/ubuntu:20.04]]) AS build
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& sed -i 's/^#\s*\(deb-src\s\)/\1/g' /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		clang \
		curl \
		devscripts \
		file \
		git \
		libasound2-dev \
		libavcodec-dev \
		libavformat-dev \
		libavutil-dev \
		libboost-atomic1.71-dev \
		libboost-chrono1.71-dev \
		libboost-date-time1.71-dev \
		libboost-filesystem1.71-dev \
		libboost-system1.71-dev \
		libboost-thread1.71-dev \
		libcurl4-openssl-dev \
		libev-dev \
		libmicrohttpd-dev \
		libmp3lame-dev \
		libncurses-dev \
		libogg-dev \
		libopenmpt-dev \
		libpulse-dev \
		libssl-dev \
		libswresample-dev \
		libsystemd-dev \
		libtag1-dev \
		libvorbis-dev \
		sqlite3 \
		tzdata

# Build CMake with "_FILE_OFFSET_BITS=64"
# (as a workaround for: https://gitlab.kitware.com/cmake/cmake/-/issues/20568)
WORKDIR /tmp/
RUN DEBIAN_FRONTEND=noninteractive apt-get build-dep -y cmake
RUN apt-get source cmake && mv ./cmake-*/ ./cmake/
WORKDIR /tmp/cmake/
RUN DEB_BUILD_PROFILES='stage1' \
	DEB_BUILD_OPTIONS='parallel=auto nocheck' \
	DEB_CFLAGS_SET='-D _FILE_OFFSET_BITS=64' \
	DEB_CXXFLAGS_SET='-D _FILE_OFFSET_BITS=64' \
	debuild -b -uc -us
RUN dpkg -i /tmp/cmake_*.deb /tmp/cmake-data_*.deb

# Build musikcube
ARG MUSIKCUBE_TREEISH=0.96.3
ARG MUSIKCUBE_REMOTE=https://github.com/clangen/musikcube.git
RUN mkdir /tmp/musikcube/
WORKDIR /tmp/musikcube/
RUN git clone "${MUSIKCUBE_REMOTE:?}" ./
RUN git checkout "${MUSIKCUBE_TREEISH:?}"
RUN git submodule update --init --recursive
RUN cmake ./ -DCMAKE_INSTALL_PREFIX=/usr
RUN make -j"$(nproc)"
RUN make install
RUN file /usr/share/musikcube/musikcube
RUN file /usr/share/musikcube/musikcubed

# Create music library db
COPY config/musikcube/1/musik.db.sql /tmp/musik.db.sql
RUN sqlite3 /tmp/musik.db < /tmp/musik.db.sql

##################################################
## "musikcube" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:20.04]], [[FROM docker.io/ubuntu:20.04]]) AS musikcube
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

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
		libavcodec-extra58 \
		libavformat58 \
		libavutil56 \
		libboost-atomic1.71.0 \
		libboost-chrono1.71.0 \
		libboost-date-time1.71.0 \
		libboost-filesystem1.71.0 \
		libboost-system1.71.0 \
		libboost-thread1.71.0 \
		libcap2-bin \
		libcurl4 \
		libev4 \
		libmicrohttpd12 \
		libmp3lame0 \
		libncursesw6 \
		libogg0 \
		libopenmpt0 \
		libpulse0 \
		libssl1.1 \
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

# Copy musikcube configuration
COPY --chown=musikcube:musikcube ./config/musikcube/ "${MUSIKCUBE_PATH}"
COPY --from=build --chown=musikcube:musikcube /tmp/musik.db "${MUSIKCUBE_PATH}"/1/musik.db

# Copy scripts
COPY --chown=root:root ./scripts/bin/ /usr/local/bin/

# Drop root privileges
USER musikcube:musikcube

## WebSocket server (metadata)
EXPOSE 7905/tcp
## HTTP server (audio)
EXPOSE 7906/tcp

WORKDIR "${MUSIKCUBE_PATH}"
ENTRYPOINT ["/usr/local/bin/container-entrypoint-cmd"]
