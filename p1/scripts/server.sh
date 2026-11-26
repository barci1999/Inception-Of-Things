#!/bin/bash
systemctl disable --now firewalld 2>/dev/null || true
IFACE=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.56\.110\// {print $2}')
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --bind-address=192.168.56.110 --tls-san=192.168.56.110 --flannel-iface=${IFACE} --write-kubeconfig-mode=644" sh -
