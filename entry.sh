#!/usr/bin/env sh

# expected env vars for slskd:
# - SLSKD_CONFIG
# - SLSKD_USERNAME
# - SLSKD_PASSWORD

GTN="${SGB_GTN_ADDR:-http://localhost:8000}"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [SGB] - ${1}"
}

is_empty() {
    if [ -z "$(eval "echo \${$1}")" ]; then
        log "$1 is not set."
        return 1
    else
        return 0
    fi
}

gluetun_port() {
    local GTN_PORTS

    if ! GTN_PORTS=$(curl --silent --fail --show-error -H "X-API-Key: ${SGB_GTN_API_KEY}" "${GTN}/v1/openvpn/portforwarded"); then
        return 1
    fi

    if echo "${GTN_PORTS}" | jq --exit-status 'has("ports")' >/dev/null; then # Handle the case of multiple ports - ex : [10550,20550,30550]
        echo "${GTN_PORTS}" | jq -er ".ports[${SGB_GTN_PORT_INDEX:-0}]"
    elif echo "${GTN_PORTS}" | jq --exit-status 'has("port")' >/dev/null; then
        echo "${GTN_PORTS}" | jq -er '.port'
    else
        return 1
    fi
}

is_empty "SLSKD_CONFIG" || exit 1
is_empty "SLSKD_USERNAME" || exit 1
is_empty "SLSKD_PASSWORD" || exit 1
is_empty "SGB_GTN_API_KEY" || exit 1

if [ ! -f "$SLSKD_CONFIG" ]; then
    log "File not found: $SLSKD_CONFIG"
    exit 1
fi

while true; do
    if ! GTN_PORT=$(gluetun_port); then
        log "Could not get forwarded port from gluetun."
    else
        log "Forwarded port retrieved from gluetun: $GTN_PORT"
    fi

    sleep "${SGB_PERIOD:-5m}"
done
