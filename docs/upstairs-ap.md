# Upstairs wired access point

Verified November 5, 2026.

The upstairs device is an ASUS RT-ACRH18 connected through a switch to a
LAN port on the main ASUS. A loose switch-uplink cable caused loss of DHCP
service upstairs. The main ASUS reported no link on the affected port;
reseating the cable restored a gigabit link and the access point became
visible again. The user confirmed internet access before the firmware update.

## Configuration and official update

The device was already in Access Point mode (`sw_mode=3`), obtaining its
management address and gateway by DHCP. WPA2-AES was enabled on both bands.
The AP mode and addressing configuration were retained.

With explicit user approval, the official firmware was upgraded from
`3.0.0.4.382_41223-gc05f969` to `3.0.0.4.382_41683-gac7107a`, and WPS was
disabled. The image was downloaded from ASUS and its extracted SHA-256
matched ASUS's published value. No custom firmware was installed.

A fresh private backup was taken before the upload. Thirty settings were
compared afterward, including both Wi-Fi names/passwords, authentication,
encryption, addressing, AP mode and radio settings. Only `extendno` and
`wps_enable` changed. Both radios remained enabled, and a wireless client
reassociated. Main-network HTTPS checks returned 200 over IPv4 and IPv6.
The user then confirmed that a phone could open a website while connected
to the upstairs access point. A final private settings backup was also saved.

The first final-backup request timed out during the wireless restart. A
subsequent live inspection verified the firmware and WPS state and obtained
a valid final backup. The firmware upload was not repeated. Temporary
firmware and private snapshots were removed from the Pi after local retrieval.

## Support status

ASUS lists this model as end-of-life. Firmware 41683, released November 30,
2023, is its final official release. The preceding 41575 release documented
WPS/IEEE-1905 and authentication-flooding fixes; the previously installed
41223 predated those releases.

Standard Merlin and GNUton do not list support for this model. SWRT lists
an older 382 branch, but a current maintained image and recovery procedure
were not verified. No OpenWrt image was verified. The recommendation is to
retain the working wired-AP role with the final official update as an interim
measure and use a supported access point for ongoing maintenance.

Credentials, Wi-Fi names/passwords, device identifiers and configuration
backups remain outside Git. See [verification](upstairs-verification.json)
and [firmware checksum](../firmware/upstairs-checksums.json).

Sources:

- [ASUS release notes and published checksum](https://www.asus.com/bt/supportonly/rt-acrh18/helpdesk_bios/)
- [ASUS end-of-life list](https://www.asus.com/event/network/eol-product/)
- [ASUS AP mode](https://www.asus.com/us/support/faq/1015009/)
- [Merlin supported models](https://github.com/RMerl/asuswrt-merlin.ng/wiki/Supported-Devices)
- [GNUton supported models](https://github.com/gnuton/asuswrt-merlin.ng)
- [SWRT model listing](https://github.com/SWRT-dev/Supported_Devices/blob/master/Firmware_Download.md)
