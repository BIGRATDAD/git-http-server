#
#
# docker-cgit Docker Container
###################
# Build Stage
###################
FROM rockylinux:9 AS builder

# Update everything; install dependencies.
RUN dnf -y update && dnf -y install \
    git gcc make \
    openssl-devel zlib-devel zip \
    highlight \
    && dnf clean all

# Build cgit.
RUN git clone https://git.zx2c4.com/cgit /build/cgit
WORKDIR /build/cgit
# Add compile-time config (cgit.conf).
ADD cgit.conf .
RUN git submodule init \
    && git submodule update \
    && make NO_LUA=1 \
    && make install DESTDIR=/build/install

###################
# Runtime Stage
###################
FROM rockylinux:9
LABEL MAINTAINER="RATDAD <lambda@disroot.org>"

# Runtime dependencies
RUN dnf -y update && dnf -y install \
    httpd git highlight \
    openssl zlib zip \
    && dnf clean all

# Install cgit artifacts.
COPY --from=builder /build/install /

# If set to 0, the container will not \
# handle git-http-backend for you.
ENV GIT_HTTP_MODE=0

# Configure Apache and cgit.
ADD etc/cgitrc /etc/cgitrc
ADD etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf

# Configure Git HTTP Modes.
ADD etc/httpd/conf.d/git-http-p.conf /etc/httpd/conf.d/git-http-p.conf
ADD etc/httpd/conf.d/git-http-cf.conf  /etc/httpd/conf.d/git-http-cf.conf
ADD etc/httpd/conf.d/git-http-pcf.conf /etc/httpd/conf.d/git-http-pcf.conf
ADD etc/httpd/conf.d/git-http-apcf.conf /etc/httpd/conf.d/git-http-apcf.conf

# Add helper scripts.
COPY opt/ /opt
RUN chmod +x /opt/*

# Prevent git-http-backend safe.directory errors.
RUN git config --system --add safe.directory /srv/git

# Entrypoint.
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# You SHOULD run this behind a reverse proxy.
# Thus, 443 isn't being exposed.
EXPOSE 80
ENTRYPOINT [ "/entrypoint.sh" ]
