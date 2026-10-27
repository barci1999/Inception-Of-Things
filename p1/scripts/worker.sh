#!/bin/bash
# (Nacho) Rocky usa firewalld en vez de ufw; K3s recomienda apagarlo.
systemctl disable --now firewalld 2>/dev/null || true
# (Nacho) Tarjeta con la IP privada, para que flannel use esa red y no la NAT.
IFACE=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.56\.111\// {print $2}')
# (Nacho) El token llega en K3S_TOKEN desde el Vagrantfile, ya no está escrito aquí.
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=${IFACE}" sh -
