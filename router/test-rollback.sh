#!/bin/sh
umask 077
touch /jffs/att-bypass/disabled
sleep 6
if [ -f /var/run/att-eapol.pid ]; then
 pid=$(cat /var/run/att-eapol.pid)
 case "$pid" in ''|*[!0-9]*) ;; *)
  if [ -r /proc/$pid/cmdline ]; then
   case "$(tr '\000' ' ' < /proc/$pid/cmdline)" in
    */jffs/att-bypass/wpa_supplicant*) kill "$pid" ;;
   esac
  fi ;;
 esac
 rm -f /var/run/att-eapol.pid
fi
nvram set wan_hwaddr_x=
nvram set wan0_hwaddr_x=
nvram set ipv6_service=disabled
nvram set ipv6_ifdev=ppp
nvram set ipv6_prefix_len_wan=64
nvram set ipv6_debug=0
service stop_dhcp6c
nvram set jffs2_scripts=0
nvram commit
service restart_wan
echo "Original WAN settings restored. Reconnect BGW210 LAN to ASUS WAN for normal service."
