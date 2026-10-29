#!/bin/bash
# P2: instala K3s en modo server y despliega las 3 apps que Vagrant ha subido a /tmp/confs.
set -euo pipefail
export PATH="/usr/local/bin:$PATH"

NODE_IP="192.168.56.110"
# Nombre de la tarjeta que tiene la IP privada (eth1, enp0s8... según la distro).
IFACE=$(ip -o -4 addr show | awk -v ip="$NODE_IP" '$4 ~ "^" ip "/" {print $2}')

# En Rocky el cortafuegos es firewalld; K3s recomienda apagarlo.
systemctl disable --now firewalld 2>/dev/null || true

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=${NODE_IP} --flannel-iface=${IFACE} --write-kubeconfig-mode=644" sh -

echo "Esperando a que el nodo esté Ready..."
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do sleep 3; done

kubectl apply -R -f /tmp/confs
for app in app-one app-two app-three; do
  kubectl rollout status "deployment/${app}" --timeout=300s
done
