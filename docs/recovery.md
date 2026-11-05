# Recovery and findings

## Return to the BGW210

The included rollback script restores this deployment's original empty WAN
clone values, disabled IPv6 mode and disabled custom-script setting. Adapt it
before use if the original configuration differs. It was syntax-checked; a
post-deployment live rollback was not performed.

1. Keep a separate working chat/recovery connection available.
2. If required, enable **LAN-only** SSH in the ASUS web interface. On this
   firmware `sshd_enable=2` means LAN-only; `1` means LAN and WAN.
3. Run `/jffs/att-bypass/test-rollback.sh` on the ASUS.
4. Return the ONT Ethernet cable to the BGW210's red ONT port.
5. Connect a BGW210 LAN port to ASUS WAN and renew/cycle the ASUS WAN connection.
6. Verify internet access before ending the recovery connection.

The BGW210 LAN was restored to `192.168.2.254/24`, with DHCP pool
`192.168.2.64` through `192.168.2.253`. Fixed passthrough was restored to the
original ASUS WAN MAC. Home internet through that topology was verified
before the direct-ONT cutover.

The unused BGW210 still has `3.18.2_ENG`. The attempted `4.26.11` update did
not apply. Restore suitable firmware before prolonged reuse; the repository
does not claim the gateway was returned to its original `4.28.8` version.

## Problems discovered during migration

### Gateway settings reset during downgrade

The BGW210 downgrade reset its LAN to the same address range as the ASUS LAN
and removed fixed passthrough. The ASUS received an overlapping WAN address
and could not route internet traffic. Restoring the gateway's previous LAN
range and fixed passthrough, then cycling ASUS WAN, restored service.

Always verify actual selected settings after firmware changes; the presence
of an option on a form does not establish that it is enabled.

### Client vanished during WAN restart

Starting authentication while the asynchronous WAN restart was still running
left no client process. The persistent supervisor starts it again after the
WAN service settles. The successful setup does not rely on a fixed
three-second restart delay.

### Certificate parsing

The client reported a missing PEM end tag for the CA bundle. Adding its
trailing newline fixed parsing. AT&T then completed EAP-TLS authentication.

### Clock reset

The ASUS booted with a January 2024 date, so AT&T's server certificate was
not yet valid. Restoring the saved clock before authentication fixed this
without disabling TLS validation. NTP then synchronized normally.

### IPv6 identity

The stock ASUS DHCPv6 client used its label-MAC DUID. AT&T did not reply.
A gateway-compatible DUID-EN with a prefix-only `/60` request received valid
responses and a working delegation. Automatic IPv4 and IPv6 recovery was
then verified after another ASUS restart.

## Private backups retained locally

- `working-ASUS-settings.CFG`: working NVRAM settings.
- `working-jffs-backup.tgz`: working scripts, hook and private credentials.
- Original ASUS settings/firmware and gateway configuration snapshots.
- Manufacturing data, extracted credentials and validation logs.

These artifacts were deliberately not committed. Keep the JFFS archive
private: it contains the authentication private key.
