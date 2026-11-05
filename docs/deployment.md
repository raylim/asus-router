# Deployment and maintenance

## Private router files

The working directory is `/jffs/att-bypass`, mode `700`. It contains:

| File | Purpose |
| --- | --- |
| `wpa_supplicant` | Community ARM client, version 2.7 |
| `libubus.so` | Runtime dependency |
| `wpa_supplicant.conf` | Local identity and credential paths |
| `client.pem` | Extracted client certificate |
| `privatekey.pem` | Matching unencrypted private key, mode `600` |
| `ca.pem` | Trusted CA bundle, with a final newline |
| `dhcp6-duid.hex` | Private gateway-compatible DUID-EN |
| `clock.epoch` | Previously verified UNIX time |
| `monitor.sh` | Persistent supervisor |
| `test-rollback.sh` | Deployment-specific recovery |

The startup hook is `/jffs/scripts/services-start`. User scripts are enabled
with `jffs2_scripts=1`. Preserve existing hooks when adapting this setup to
another router; this deployment had no existing startup hook.

The authentication binary is invoked through:

```sh
/lib/ld-linux.so.3 --library-path /jffs/att-bypass:/usr/lib \
  /jffs/att-bypass/wpa_supplicant
```

The tested community binary's SHA-256 is
`f2f6a5ca7524f69050251d3315f9cd43e065365b2cfbaa328efe9b05a35cddd6`.
It requires the matching ARM runtime. Recheck runtime compatibility after
firmware upgrades. The binary and dependencies are not distributed here.

## Reconstructing the configuration

Use private backups for the certificate/key material. Match the certificate
public key to the private key and validate the chain and dates before use.
The deployed client certificate was valid when tested; the chain also passed
signature and date validation.

Copy the example configuration locally and replace `<GATEWAY_WAN_MAC>` with
the gateway certificate identity. Set the ASUS WAN clone fields
`wan_hwaddr_x` and `wan0_hwaddr_x` to that same MAC. Save the original values
before changing them.

The client rejected a CA bundle without a final newline. Preserve the final
newline in all PEM files. Do not bypass certificate verification to work
around formatting or clock errors.

The gateway-compatible DUID used the documented ARRIS format: DUID type `2`,
enterprise number `3561`, followed by ASCII `001E46-<gateway serial>`.
Generate it locally without placing the serial number in shell history:

```sh
mkdir -p private
chmod 700 private
# Populate private/gateway-serial.txt locally, then:
python3 tools/make_duid.py < private/gateway-serial.txt > private/dhcp6-duid.hex
chmod 600 private/dhcp6-duid.hex
```

The IPv6 settings are:

```text
ipv6_service=dhcp6
ipv6_ifdev=eth
ipv6_dhcp_pd=1
ipv6_prefix_len_wan=60
ipv6_dnsenable=1
ipv6_radvd=1
ipv6_autoconf_type=0
ipv6_fw_enable=1
ipv6_debug=0
```

The custom DHCPv6 invocation uses the firmware's built-in callback:

```sh
odhcp6c -df -R -s /tmp/dhcp6c -N none \
  -c "$(cat /jffs/att-bypass/dhcp6-duid.hex)" -P 60:1 -r23 -r24 eth0
```

This does not configure Pi-hole-specific IPv6 DNS filtering. The verified
checks establish DNS resolution and Pi-hole availability, not filtering of
every client's IPv6 DNS traffic.

## Supervisor behavior

The startup hook runs the monitor in the background. Its loop:

1. Checks that the WAN MAC matches the configured identity.
2. Restarts the EAP client if its PID is absent or no longer belongs to it.
3. Requests another IPv4 DHCP lease, at most every 30 seconds while disconnected,
   because the initial DHCP attempt can precede authentication.
4. When IPv4 is connected and Native IPv6 is enabled, maintains the custom
   DHCPv6 request instead of the stock ASUS DUID.
5. Updates the saved clock at most once per day after NTP synchronization.

Creating `/jffs/att-bypass/disabled` stops the monitor. The rollback script
uses that flag before restoring the previous WAN identity.

## Verification after changes

- Inspect `/tmp/att-eapol.log` for `CTRL-EVENT-EAP-SUCCESS`.
- Check WAN state `2`, reason `0`, and a public address.
- Verify a global IPv6 address and default route on a LAN client.
- Run HTTPS checks separately with `curl -4` and `curl -6`.
- Check the IPv6 firewall, DNS, and local services.
- Restart the ASUS and repeat the checks to prove persistence.

Keep logs and configuration snapshots private. The settings backup does not
replace a JFFS backup: the latter contains the custom scripts and credentials.
