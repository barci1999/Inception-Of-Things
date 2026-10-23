#!/bin/bash
sudo ufw disable 2>/dev/null || true
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" K3S_TOKEN="mi_token_secreto_42" INSTALL_K3S_EXEC="--node-ip=192.168.56.111" sh -