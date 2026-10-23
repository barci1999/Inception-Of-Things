#!/bin/bash
sudo ufw disable 2>/dev/null || true
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --bind-address=192.168.56.110 --tls-san=192.168.56.110 --token mi_token_secreto_42" sh -