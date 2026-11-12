#!/bin/bash
set -euo pipefail
export PATH="/usr/local/bin:$PATH"

NODE_IP="192.168.56.110"
IFACE=$(ip -o -4 addr show | awk -v ip="$NODE_IP" '$4 ~ "^" ip "/" {print $2}')

systemctl disable --now firewalld 2>/dev/null || true

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=${NODE_IP} --flannel-iface=${IFACE} --write-kubeconfig-mode=644" sh -

echo "Esperando a que el nodo esté Ready..."
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do sleep 3; done

kubectl apply -R -f /tmp/confs
for app in app-one app-two app-three; do
  kubectl rollout status "deployment/${app}" --timeout=300s
done
