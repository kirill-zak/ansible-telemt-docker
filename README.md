# ansible_telemt_docker

An Ansible role that deploys the [TelemT](https://github.com/telemt/telemt) MTProto
proxy for Telegram as a Podman container with a production-hardened configuration.

The role renders a `telemt.toml` configuration file, stores it in a dedicated
Podman volume, and runs the TelemT container against it. When the rendered
config changes, the role copies the new file into the volume and recreates the
container automatically.

## Requirements

- A target host with a running Podman engine (the `podman` CLI; the default
  rootful socket is `/run/podman/podman.sock` — for non-default socket paths
  point the CLI at it with the `CONTAINER_HOST` environment variable or a
  podman connection).
- The `containers.podman` and `ansible.posix` collections (see `requirements.yml`).

## Role Variables

All variables are defined in [`defaults/main.yml`](defaults/main.yml) and can be
overridden per host/group or passed as role parameters.

### General Settings

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_use_middle_proxy` | bool | `true` | Enable an intermediate/upstream proxy (e.g. to hide traffic). |
| `telemt_ad_tag` | string | unset | Global `ad_tag` fallback for users without a per-user tag. |
| `telemt_log_level` | string | `"normal"` | Log level: `debug` \| `verbose` \| `normal` \| `silent`. |

### Modes

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_mode_classic` | bool | `false` | Enable classic proxy mode. |
| `telemt_mode_secure` | bool | `false` | Enable secure proxy mode. |
| `telemt_mode_tls` | bool | `true` | Enable TLS (fake-TLS) proxy mode. |

### Links

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_links_show` | string/list | `"*"` | Show generated links for selected users; `"*"` means all. |
| `telemt_links_public_host` | string | `""` | Host used for `tg://` links; empty disables the override. |
| `telemt_links_public_port` | string | `""` | Port used for `tg://` links (defaults to `server.port`). |

### Server Binding

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_server_port` | int | `443` | Proxy listen port. |
| `telemt_server_proxy_protocol` | bool | `false` | Enable PROXY protocol (only behind HAProxy/nginx). |
| `telemt_server_metrics_port` | int | `9090` | Standalone metrics port (`0` disables the listener). |
| `telemt_server_metrics_listen` | string | `""` | Optional metrics listen address; overrides `metrics_port`. |
| `telemt_server_metrics_whitelist` | list | `[]` | IP whitelist for metrics access, e.g. `["127.0.0.1/32"]`. |

### Server API

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_api_enabled` | bool | `true` | Enable the management API. |
| `telemt_api_listen` | string | `"127.0.0.1:9091"` | API listen address. |
| `telemt_api_whitelist` | list | `["127.0.0.1/32", "::1/128"]` | IP whitelist for the API. |
| `telemt_api_minimal_runtime_enabled` | bool | `false` | Run without full runtime state. |
| `telemt_api_minimal_runtime_cache_ttl_ms` | int | `1000` | TTL of the minimal-runtime cache in milliseconds. |

### Listeners

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_listeners` | list | `[{ip: "0.0.0.0"}]` | Addresses the proxy binds to; one `[[server.listeners]]` block per entry. |

### Censorship & Masking

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_tls_domain` | string | `"petrovich.ru"` | Fake-TLS / SNI masking domain. Changing it invalidates existing TLS links. |
| `telemt_mask` | bool | `true` | Mask traffic to look like normal web traffic. |
| `telemt_tls_emulation` | bool | `true` | Fetch real cert lengths and emulate TLS records. |
| `telemt_tls_front_dir` | string | `"tlsfront"` | Cache directory for TLS emulation. |

### Access Users

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_access_users` | dict | unset | Map of `username: "32_hex_secret"` entries in `[access.users]`. |
| `telemt_access_user_ad_tags` | dict | `{}` | Map of `username: "32_hex_ad_tag"` entries in `[access.user_ad_tags]`. |

### Configuration File

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_config_path` | string | `"/etc/telemt/telemt.toml"` | Path to the rendered configuration file on the target host. |

### Podman Container

| Variable | Type | Default | Description |
|---|---|---|---|
| `telemt_image` | string | `"whn0thacked/telemt-docker"` | TelemT container image. |
| `telemt_image_version` | string | `"latest"` | Image tag/version. |
| `telemt_config_volume` | string | `"telemt-config"` | Podman volume persisting the generated config. |
| `telemt_container_name` | string | `"telemt"` | Name of the running container. |
| `telemt_container_restart_policy` | string | `"unless-stopped"` | Container restart policy. |
| `telemt_container_config_path` | string | `"/etc/telemt/telemt.toml"` | Config path inside the container. |
| `telemt_container_command` | list | `["{{ telemt_container_config_path }}"]` | Command passed to the entrypoint. |
| `telemt_network_mode` | string | `"host"` | Container network mode. |
| `telemt_published_ports` | list | `["443:443/tcp"]` | Published ports (only used when network mode is not `host`). |
| `telemt_container_user` | string | `""` | Container user; empty runs as default. |
| `telemt_security_opts` | list | `["no-new-privileges:true"]` | Extra security options. |
| `telemt_cap_drop` | list | `["ALL"]` | Capabilities dropped from the container. |
| `telemt_cap_add` | list | `["NET_BIND_SERVICE"]` | Capabilities added back. |
| `telemt_read_only` | bool | `true` | Run the container root filesystem read-only (all writable state lives in the config volume). |
| `telemt_resource_limits_cpus` | string | `"0.50"` | CPU limit (0.50 = half a core). |
| `telemt_resource_limits_memory` | string | `"256M"` | Memory limit. |
| `telemt_resource_reservations_memory` | string | `"128M"` | Reserved memory guarantee. |
| `telemt_ulimits` | list | `["nofile=65536:65536"]` | File descriptor soft/hard limits (`name=SOFT:HARD`). |
| `telemt_log_driver` | string | `"json-file"` | Logging driver. |
| `telemt_log_options` | dict | `{max_size: "10m"}` | Logging driver options (`max_size`, `path`, `tag`). |

## Generating Access User Secrets

Each entry in `telemt_access_users` maps a `username` to a secret of exactly
32 hex characters (16 random bytes, 128 bits of entropy). Telemt embeds the
secret into the generated client link (`https://username:secret@host/`), so
it is effectively the user's password: generate one fresh value per user and
keep the values in an encrypted variable (e.g. Ansible Vault) instead of
committing them to version control.

The role defines no users by default, and telemt refuses to start with an
empty `[access.users]` section, so at least one user is required.

Generate a secret:

```bash
# OpenSSL (Linux/macOS)
openssl rand -hex 16

# Python
python3 -c "import secrets; print(secrets.token_hex(16))"
```

Example:

```yaml
telemt_access_users:
  alice: "5f2c9d8a7b6e41f0a3d2c1b0e9f8a7d6"
  bob: "c0ffee00011122233344455566677788"
```

Changing a user's secret (or `telemt_tls_domain`) invalidates links
previously generated for that user. Per-user advertising tags in
`telemt_access_user_ad_tags` use the same 32-hex format.

## Dependencies

- `containers.podman` collection
- `ansible.posix` collection

## Example Playbook

```yaml
- hosts: proxy
  become: true
  roles:
    - role: kirill_zak.ansible_telemt_docker
      vars:
        telemt_access_users:
          alice: "00000000000000000000000000000000"
        telemt_links_public_host: "proxy.example.com"
        telemt_log_level: "verbose"
```

## License

MIT

## Author Information

- Author: Kirill Ziuzin
- Website: https://kirill-zak.ru