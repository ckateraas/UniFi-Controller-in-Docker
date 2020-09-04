FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
ARG PKGURL=https://dl.ubnt.com/unifi/5.12.66/unifi_sysvinit_all.deb
ARG UNIFI_GID=999
ARG UNIFI_UID=999

RUN groupadd -r unifi -g $UNIFI_GID
RUN useradd --no-log-init -r -u $UNIFI_UID -g $UNIFI_GID unifi

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y curl gnupg2

COPY unifi.deb.sha256sum /unifi.deb.sha256sum
RUN curl -L -o unifi.deb "${PKGURL}"
RUN sha256sum -c unifi.deb.sha256sum

RUN curl -s https://www.mongodb.org/static/pgp/server-3.6.asc | apt-key add -
RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.6.list
RUN apt-get update 
RUN apt-get install -y mongodb-org-server jsvc \
    openjdk-8-jre-headless binutils libcap2 \
    logrotate
RUN dpkg --install unifi.deb
RUN rm unifi.deb unifi.deb.sha256sum

COPY functions /functions

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

WORKDIR /unifi
RUN chown -R unifi:unifi /unifi /usr/lib/unifi

USER unifi

EXPOSE 6789/tcp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 3478/udp

ENTRYPOINT ["/entrypoint.sh"]