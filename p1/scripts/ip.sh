#!/bin/bash
# (Nacho) Pone la IP fija de la red privada con NetworkManager. Uso: ip.sh 192.168.56.110
# No lo dejamos en manos de Vagrant: el Vagrant 2.4.1 de los ordenadores de 42 no la pone
# en Fedora 45, y la tarjeta se quedaba con una IP automática (.101) de la red de VirtualBox.
set -eu
IP="$1"

# La tarjeta privada es la que no lleva la salida a Internet (esa es la NAT de Vagrant).
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
