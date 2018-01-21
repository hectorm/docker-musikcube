FROM ubuntu:16.04

ARG GOLANG_RELEASE_URL=https://dl.google.com/go/go1.9.2.linux-amd64.tar.gz
ARG MUSIKCUBE_GIT_REPOSITORY=https://github.com/clangen/musikcube.git
ARG MUSIKCUBE_GIT_BRANCH=master
ARG MUSIKCUBE_PASSWORD

ENV DEBIAN_FRONTEND noninteractive

ENV CORE_DEPENDENCIES \
	libasound2 \
	libboost-atomic1.58.0 \
	libboost-chrono1.58.0 \
	libboost-date-time1.58.0 \
	libboost-filesystem1.58.0 \
	libboost-system1.58.0 \
	libboost-thread1.58.0 \
	libcurl3 \
	libfaad2 \
	libflac8 \
	libmicrohttpd10 \
	libmp3lame0 \
	libncursesw5 \
	libogg0 \
	libpulse0 \
	libvorbis0a \
	locales \
	pulseaudio

ENV BUILD_DEPENDENCIES \
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
	libfaad-dev \
	libflac-dev \
	libmicrohttpd-dev \
	libmp3lame-dev \
	libncursesw5-dev \
	libogg-dev \
	libpulse-dev \
	libvorbis-dev \
	sqlite3

# Add musikcube user
RUN useradd \
	--uid 1000 \
	--user-group \
	--create-home \
	--home-dir /home/musikcube \
	musikcube

# Copy scripts and configurations
COPY --chown=root:root config/pulse-client.conf /etc/pulse/client.conf
COPY --chown=root:root scripts/docker-musikcube-entrypoint /usr/local/bin/
COPY --chown=musikcube:musikcube config/Caddyfile /home/musikcube/
COPY --chown=musikcube:musikcube config/musikcube /home/musikcube/.musikcube

RUN uname --all \
	# Install dependencies
	&& apt-get update \
	&& apt-get install \
		--assume-yes \
		--option Dpkg::Options::='--force-confdef' \
		--option Dpkg::Options::='--force-confold' \
		--no-install-recommends \
		${CORE_DEPENDENCIES} ${BUILD_DEPENDENCIES} \
	# Setup locale
	&& locale-gen en_US.UTF-8 \
	# Download Go
	&& mkdir /tmp/goroot /tmp/gopath \
	&& export GOROOT=/tmp/goroot \
	&& export GOPATH=/tmp/gopath \
	&& export PATH="${PATH}:${GOROOT}/bin" \
	&& curl -fsSL "${GOLANG_RELEASE_URL}" | tar xzf - --strip-components=1 -C "${GOROOT}" \
	# Build Caddy
	&& go get -u github.com/mholt/caddy \
	&& go get -u github.com/caddyserver/builds \
	&& cd "${GOPATH}/src/github.com/mholt/caddy/caddy" \
	&& go run build.go \
	&& ./caddy --version \
	&& ./caddy --plugins \
	&& mv ./caddy /usr/local/bin/caddy \
	# Build musikcube
	&& mkdir /tmp/musikcube \
	&& cd /tmp/musikcube \
	&& git clone "${MUSIKCUBE_GIT_REPOSITORY}" --recursive . \
	&& git checkout "${MUSIKCUBE_GIT_BRANCH}" \
	&& cmake . \
	&& make -j$(nproc) \
	&& cmake . \
	&& make install \
	# Set musikcube server password
	&& cd /home/musikcube/.musikcube \
	&& perl -i -pe 's/%PASSWORD%/$ENV{MUSIKCUBE_PASSWORD}/g' 'plugin_musikcubeserver(wss,http).json' \
	# Create music library
	&& mkdir /music \
	&& cd /home/musikcube/.musikcube/1 \
	&& sqlite3 musik.db < musik.db.sql \
	&& chown musikcube:musikcube musik.db \
	# Cleanup
	&& apt-get remove -y ${BUILD_DEPENDENCIES} \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/* /tmp/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

VOLUME /music
WORKDIR /home/musikcube

EXPOSE 7905 7906

USER musikcube:musikcube

ENTRYPOINT ["docker-musikcube-entrypoint"]
CMD ["sh", "-c", "musikcube >/dev/null"]
