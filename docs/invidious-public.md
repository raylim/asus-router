# Public Invidious over HTTPS

Deployed November 5, 2026. Phone access does not require Tailscale.

Public IPv4 TCP 443 forwards to the Pi TCP 8443. A dedicated Caddy container
proxies to `invidious:3000` on the existing Docker network. The Pi's existing
ports 80 and 443 remain untouched; no new IPv6 inbound rule was added.
Existing Minecraft forwarding rules were preserved. The Pi already has a DHCP
reservation. Actual addresses and router backups remain private.

Templates are in `examples/invidious-public/`. The deployed directory is
`/home/rlim/invidious-public` on the Pi. Supply the current WAN IPv4 in `.env`.
The image is pinned to the deployed official Caddy digest. Persistent Docker
volumes retain ACME account and certificate data. Keep those volumes private.
Caddy uses Let's Encrypt's short-lived IP certificates and renews automatically
using TLS-ALPN on public TCP 443. Port 80 is not needed for this configuration.
`default_sni` selects the IP certificate for clients that omit SNI.

In `/home/rlim/invidious/docker-compose.pi.yml`, the embedded
`INVIDIOUS_CONFIG` now sets `domain` to the WAN IPv4, `external_port: 443`, and
`https_only: true`. All other application configuration was preserved. Only the
Invidious application container was recreated; database and companion were not.
The original compose file is backed up privately in the proxy directory.

Verification: public-IP HTTPS request returned 200 after one redirect, with
strict certificate verification passing and Invidious content present.
Let's Encrypt independently completed external TLS-ALPN validation. Proxy,
Invidious, database and companion containers are running; Pi-hole remains active.
Phone playback confirmation is pending. This does not establish video playback
or performance under public load.

If the ISP changes the WAN IPv4, update `.env` and the Invidious domain setting,
then recreate the proxy and application containers. The old address will no
longer work. The host kernel currently ignores Docker memory limits because
its memory cgroup controller is unavailable; the configured limit is not enforced.

## Recovery

Remove only the `Invidious-HTTPS` forwarding entry in the ASUS UI, preserving
all other rules, to immediately stop public access. Stop the proxy with
`docker compose stop proxy` from its directory. Retain its certificate volumes.
Restore the private original Invidious compose file and recreate only its
application service if the public link settings also need to be reverted.
Do not forward directly to the Pi's ports 80 or 443, which serve existing software.

Sources: [Caddy TLS](https://caddyserver.com/docs/caddyfile/directives/tls),
[Caddy global options](https://caddyserver.com/docs/caddyfile/options),
[Let's Encrypt IP certificates](https://letsencrypt.org/2026/01/15/6day-and-ip-general-availability),
[Invidious reverse proxy](https://docs.invidious.io/nginx/).
