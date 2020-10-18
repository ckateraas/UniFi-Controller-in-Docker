#! /usr/bin/env bash

set -euo pipefail

function allow_full_access_to_unifi() {
    ufw allow from "$1" to any port 3478 proto udp
    ufw allow from "$1" to any port 6789 proto tcp
    ufw allow from "$1" to any port 8080 proto tcp
    ufw allow from "$1" to any port 8443 proto tcp
    ufw allow from "$1" to any port 8880 proto tcp
    ufw allow from "$1" to any port 8843 proto tcp
    ufw allow from "$1" to any port 10001 proto udp
}

# Allow full to access the host
# allow_full_access_to_unifi <IP>

ufw default allow outgoing
ufw default deny incoming

ufw allow ssh

ufw enable