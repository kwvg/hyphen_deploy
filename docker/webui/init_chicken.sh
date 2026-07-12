#!/bin/bash

set -eux

SELF=$(basename "$0")

if ! command -v openssl &>/dev/null; then
    echo "${SELF}: openssl binary not found" >&2
    exit 1
fi

CERT_BASE="/etc/nginx/ssl/live"
CHICKEN_BOOTSTRAP_O="Fictitious Improvised Root CA"
NGINX_CONF="/config/nginx/site-confs/default.conf"
DOMAINS=$(awk '/^map \$host \$backend/,/^}/ { if ($1 ~ /\./) print $1 }' "${NGINX_CONF}" | sort -u)

for domain in $DOMAINS; do
    dir="${CERT_BASE}/${domain}"
    if [ -f "${dir}/fullchain.pem" ] && [ -f "${dir}/privkey.pem" ]; then
        continue
    fi
    echo "${SELF}: generating bootstrap cert for ${domain}"
    mkdir -p "${dir}"
    openssl ecparam -genkey -name prime256v1 -noout -out "${dir}/privkey.pem"
    openssl req -new -x509 -key "${dir}/privkey.pem" -out "${dir}/fullchain.pem" \
        -days 1 -subj "/O=${CHICKEN_BOOTSTRAP_O}/CN=${domain}"
done
