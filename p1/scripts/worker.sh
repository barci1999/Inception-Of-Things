#!/bin/bash
systemctl disable --now firewalld 2>/dev/null || true
IFACE=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.56\.111\// {print $2}')
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=${IFACE}" sh -
