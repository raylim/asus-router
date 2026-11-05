# ASUS direct-ONT AT&T setup

Working configuration for replacing an AT&T BGW210-700 with an existing ASUS
RT-AX3000. The actual firmware platform is **RT-AX58U_V2**; it uses GNUton
Asuswrt-Merlin **3004.388.11_1-gnuton1**.

The deployed connection is:

```text
AT&T fiber -> external ONT -> ASUS WAN (eth0) -> home LAN
```

Successful EAP-TLS authentication, public IPv4 service, native IPv6, and
automatic recovery after an ASUS reboot were verified on November 4, 2026.
The LAN Raspberry Pi returned HTTPS 200 over both IPv4 and IPv6 after the final
restart. DNS, Pi-hole and Home Assistant checks also passed.

**Spare gateway:** the BGW210 still has extraction firmware `3.18.2_ENG`.
An attempted update to `4.26.11` rebooted but did not apply. Its LAN and
passthrough settings were restored and used successfully before the final
cutover. Keep the unused gateway powered off pending firmware restoration.

## Repository contents

- `router/monitor.sh`: working authentication, clock and DHCPv6 supervisor.
- `router/services-start`: Merlin startup hook.
- `router/test-rollback.sh`: rollback for this deployment's original settings.
- `examples/wpa_supplicant.conf.example`: configuration with a placeholder identity.
- `tools/`: web-access helpers and a gateway DUID generator.
- `docs/`: deployment, recovery, troubleshooting and verification records.
- `firmware/checksums.json`: hashes of locally examined BGW210 images.

Firmware binaries, credentials, gateway serial numbers, MAC identities,
certificates, private keys, manufacturing data and device backups stay outside
Git. The working router has already been configured; cloning this repository
does not change it.

## How the working setup behaves

The supervisor starts a community `wpa_supplicant` 2.7 binary with the wired
driver and the gateway's extracted EAP-TLS credentials. The WAN MAC is cloned
to the gateway certificate identity. No additional manually configured VLAN
was required on this ASUS; carrier-side tagging was not captured separately.

The router boots with an incorrect date, so a saved, previously verified clock
is restored before TLS authentication. Once NTP is synchronized, that saved
clock is refreshed at most daily. Certificate validation remains enabled.

For IPv6, the stock ASUS DUID received no reply. A gateway-compatible DUID-EN,
prefix-only request, `/60` delegation and association ID `1` obtained a working
prefix. The built-in ASUS DHCPv6 callback configures LAN addressing and router
advertisements. The supervisor replaces the stock DHCPv6 client when needed.

IPv6 firewalling is enabled. Forwarding defaults to DROP, and input has
terminal drop rules. Temporary SSH access was disabled again after verification.

See [deployment](docs/deployment.md), [recovery](docs/recovery.md), and
[verification](docs/verification.json). BitTorrent load stability and sustained
throughput were not tested.

## Sources

- [GNUton firmware](https://github.com/gnuton/asuswrt-merlin.ng)
- [Merlin user scripts](https://github.com/RMerl/asuswrt-merlin.ng/wiki/User-scripts)
- [Community ASUS authentication client](https://github.com/bypassrg/att)
- [Certificate decoder used during recovery](https://github.com/rssor/extract_bgw_certs)
- [pfatt IPv6 and DUID instructions](https://github.com/MonkWho/pfatt)
- [DUID generator reference](https://github.com/MonkWho/pfatt/blob/master/bin/gen-duid.sh)

This records a verified deployment, rather than a claim that the same firmware,
ONT or bypass method works on every AT&T installation.
