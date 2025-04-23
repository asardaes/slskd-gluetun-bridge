A simple containerized script to sync [gluetun's](https://github.com/qdm12/gluetun) forwarded port with [slskd's](https://github.com/slskd/slskd) YAML config,
updating the file directly without going through slskd's REST API.
Logic draws in part from [this mod](https://github.com/t-anc/GSP-Qbittorent-Gluetun-sync-port-mod).

# Setup

Mandatory environment variables:

- `SLSKD_CONFIG`: path to `slskd.yml` inside the container.
- `SGB_GTN_API_KEY` or `SGB_GTN_API_KEY_FILE`: the former specifies the key to talk to gluetun directly, the latter specifies a file with the key inside the container (for secrets).

Additionally, you must specify at least the following in `slskd.yml`:

```yaml
soulseek:
  listen_port: 50300
```

Optional environment variables:

- `SGB_GTN_ADDR`: address to reach gluetun including scheme and port.
- `SGB_GTN_PORT_INDEX`: index within the `ports` array in gluetun's response in case multiple ports are forwarded.
- `SGB_PERIOD`: how often to check the port reported by gluetun and compare it with what's in `slskd.yml`.
  It must be something `sleep` understand and defaults to `5m`.

See [`compose.yaml`](compose.yaml) for an example,
and note that the script runs as root because I set the secret file's permissions as 600,
which docker reflects in the file created inside the container under `/run/secrets`.
