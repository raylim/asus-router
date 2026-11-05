#!/bin/sh
umask 077
[ -f /jffs/att-bypass/disabled ] && exit 0
mkdir /tmp/att-bypass-monitor.lock 2>/dev/null || exit 0
echo $$ > /tmp/att-bypass-monitor.pid
trap 'rm -f /tmp/att-bypass-monitor.pid; rmdir /tmp/att-bypass-monitor.lock 2>/dev/null' EXIT HUP INT TERM
# The router has no battery-backed clock. Restore a recently verified time
# before TLS certificate checks; retain full certificate validation.
saved_clock=$(cat /jffs/att-bypass/clock.epoch 2>/dev/null)
case "$saved_clock" in ''|*[!0-9]*) ;; *)
 if [ "$(date +%s)" -lt "$saved_clock" ]; then
  date -u -s "@$saved_clock" > /dev/null
 fi ;;
esac
expected=$(sed -n 's/^[ \t]*identity="\([^"]*\)".*/\1/p' /jffs/att-bypass/wpa_supplicant.conf | tr A-F a-f)
client_running() {
 [ -r /var/run/att-eapol.pid ] || return 1
 pid=$(cat /var/run/att-eapol.pid)
 case "$pid" in ''|*[!0-9]*) return 1;; esac
 kill -0 "$pid" 2>/dev/null || return 1
 [ -r /proc/$pid/cmdline ] || return 1
 case "$(tr '\000' ' ' < /proc/$pid/cmdline)" in
  */jffs/att-bypass/wpa_supplicant*) return 0;;
 esac
 return 1
}
lease_retry=0
while [ ! -f /jffs/att-bypass/disabled ]; do
 actual=$(cat /sys/class/net/eth0/address 2>/dev/null)
 if [ "$actual" = "$expected" ] && ! client_running; then
  /lib/ld-linux.so.3 --library-path /jffs/att-bypass:/usr/lib /jffs/att-bypass/wpa_supplicant -t -Dwired -ieth0 -c/jffs/att-bypass/wpa_supplicant.conf >> /tmp/att-eapol.log 2>&1 < /dev/null &
  echo $! > /var/run/att-eapol.pid
 fi
 # DHCP may have tried before EAP completed. Request a fresh lease
 # without restarting WAN or disrupting the authentication process.
 if [ "$(nvram get wan0_state_t)" != "2" ] && [ "$lease_retry" -le 0 ]; then
  dhcp4_pid=$(cat /var/run/udhcpc0.pid 2>/dev/null)
  case "$dhcp4_pid" in ''|*[!0-9]*) ;; *) kill -USR1 "$dhcp4_pid" 2>/dev/null;; esac
  lease_retry=6
 fi
 [ "$lease_retry" -gt 0 ] && lease_retry=$((lease_retry - 1))
 # ASUS generates a DUID-LL from its label MAC. AT&T requires the
 # gateway-compatible DUID-EN and a /60 request for this connection.
 if [ "$(nvram get ipv6_service)" = "dhcp6" ] && [ "$(nvram get wan0_state_t)" = "2" ]; then
  duid=$(cat /jffs/att-bypass/dhcp6-duid.hex 2>/dev/null)
  correct_client=0
  case "$duid" in ''|*[!0-9a-fA-F]*) ;; *)
   for dhcp_pid in $(pidof odhcp6c); do
    [ -r /proc/$dhcp_pid/cmdline ] || continue
    dhcp_args=$(tr '\000' ' ' < /proc/$dhcp_pid/cmdline)
    case "$dhcp_args" in *"-c $duid "*"-P 60:1 "*) correct_client=1;; esac
   done
   if [ "$correct_client" = "0" ]; then
    killall odhcp6c 2>/dev/null
    odhcp6c -df -R -s /tmp/dhcp6c -N none -c "$duid" -P 60:1 -r23 -r24 eth0
   fi ;;
  esac
 fi
 # Save an NTP-synchronized clock at most once per day.
 if [ "$(nvram get ntp_ready)" = "1" ]; then
  epoch_now=$(date +%s)
  epoch_saved=$(cat /jffs/att-bypass/clock.epoch 2>/dev/null)
  case "$epoch_saved" in ''|*[!0-9]*) epoch_saved=0;; esac
  if [ "$epoch_now" -gt "$((epoch_saved + 86400))" ]; then
   echo "$epoch_now" > /jffs/att-bypass/clock.epoch
  fi
 fi
 sleep 5
done
