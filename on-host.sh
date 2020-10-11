#! /usr/bin/env bash

PKGURL="https://dl.ui.com/unifi/5.14.43/unifi_sysvinit_all.deb"

set -e

if grep -q "^unifi:" /etc/group; then
    echo "Group for unifi already exists"
else
    echo "Adding new group, unifi"
    groupadd --system unifi
fi

if grep -q "^unifi:" /etc/passwd; then
    echo "User for unifi already exists"
else
    echo "Adding new user, unifi"
    useradd --no-log-init --no-create-home --shell $(which nologin) --system -g unifi unifi
fi

echo "Updating and upgrading APT"
apt-get update
apt-get upgrade -y

echo "Installing dependencies"
apt-get install -y curl openjdk-8-jre-headless logrotate

echo "Fetching key for MongoDB's PPA"
curl -s https://www.mongodb.org/static/pgp/server-3.6.asc | apt-key add -

echo "Adding MongoDB's PPA as APT source"
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/3.6 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.6.list

echo "Updating APT"
apt-get update 

echo "Installing Mongo DB with APT"
apt-get install -y unifi

mkdir -p /usr/lib/unifi
chown -R unifi:unifi /usr/lib/unifi
cp system.properties /usr/lib/unifi/data/system.properties

echo "Start the Unifi Controller by first starting MongoDB, then Unifi"
echo "systemctl enable mongod"
echo "systemctl start mongod"
echo "systemctl enable unifi"
echo "systemctl start unifi"