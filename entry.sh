#!/usr/bin/env sh

# expected env vars for slskd:
# - SLSKD_CONFIG
# - SLSKD_USERNAME
# - SLSKD_PASSWORD

GTN="${SGB_GTN_ADDR:-http://localhost:8000}"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [SGB] - ${1}"
}

is_set() {
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

is_set "SLSKD_CONFIG" || exit 1
is_set "SLSKD_USERNAME" || exit 1
is_set "SLSKD_PASSWORD" || exit 1

if is_set "SGB_GTN_API_KEY_FILE" && test -s "$SGB_GTN_API_KEY_FILE"; then
    SGB_GTN_API_KEY=$(cat "$SGB_GTN_API_KEY_FILE")
elif ! is_set "SGB_GTN_API_KEY"; then
    exit 1
fi

if [ ! -f "$SLSKD_CONFIG" ]; then
    log "File not found: $SLSKD_CONFIG"
    exit 1
elif ! grep -m 1 "listen_port" "$SLSKD_CONFIG" &>/dev/null; then
    log "File $SLSKD_CONFIG does not specify 'listen_port', please set it explicitly with the default value."
    exit 1
fi

while true; do
    if ! GTN_PORT=$(gluetun_port); then
        log "Could not get forwarded port from gluetun."
    else
        SLSKD_PORT=$(grep -m 1 "listen_port" "$SLSKD_CONFIG" | cut -d ':' -f 2 | xargs)
        if [ "$SLSKD_PORT" = "$GTN_PORT" ]; then
            log "Forwarded port retrieved from gluetun ($GTN_PORT) is already configured in slskd."
        else
            sed '/listen_port/s/\( *listen_port\):.*/\1: '"$GTN_PORT/" "$SLSKD_CONFIG" >/tmp/slskd.yml \
                && cp /tmp/slskd.yml "$SLSKD_CONFIG" \
                && log "Updated $SLSKD_CONFIG with $(grep -m 1 "listen_port" "$SLSKD_CONFIG" | xargs)"
        fi
    fi

    sleep "${SGB_PERIOD:-5m}"
done
