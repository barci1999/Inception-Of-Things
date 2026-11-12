#!/bin/bash

NAMESPACE="argocd"
PORT=8443

PASSWORD=$(sg docker -c "kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null" | base64 -d)
if [ -z "$PASSWORD" ]; then
    echo "❌ Error: Argo CD is not installed. Run initArgo.sh first."
    exit 1
fi

echo "===================================================="
echo "🌐 Argo CD UI: https://localhost:$PORT"
echo "👤 Username: admin"
echo "🔑 Password: $PASSWORD"
echo "   (Ctrl+C to stop)"
echo "===================================================="
sg docker -c "kubectl -n $NAMESPACE port-forward --address 0.0.0.0 svc/argocd-server $PORT:443"
