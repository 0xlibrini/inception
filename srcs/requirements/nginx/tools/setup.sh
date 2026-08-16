#!/bin/bash

set -e

CERT_DIR="/etc/nginx/ssl"
mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_DIR/inception.crt" ]; then
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$CERT_DIR/inception.key" \
        -out "$CERT_DIR/inception.crt" \
        -subj "/C=MA/ST=Morocco/L=City/O=1337/CN=anlibrin.42.fr"
fi

exec nginx -g "daemon off;"