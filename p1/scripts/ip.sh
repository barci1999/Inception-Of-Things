#!/bin/bash
set -eu
IP="$1"

NAT=$(ip route show default | awk '{print $5; exit}')
IFACE=$(ls /sys/class/net | grep -E '^(eth|en)' | grep -vx "$NAT" | awk 'NR==1')
if [ -z "$IFACE" ]; then
  echo "No encuentro la tarjeta de la red privada" >&2
  exit 1
fi

nmcli connection delete iot-privada >/dev/null 2>&1 || true
nmcli connection add type ethernet ifname "$IFACE" con-name iot-privada \
  ipv4.method manual ipv4.addresses "$IP/24" ipv6.method disabled \
  connection.autoconnect yes connection.autoconnect-priority 100
nmcli connection up iot-privada
ip -4 addr show "$IFACE"
