#!/bin/bash

NAMESPACE="argocd"
MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo "🐙 Installing Argo CD into namespace '$NAMESPACE'..."

# 1. Aplicar manifiestos oficiales de Argo CD
sg docker -c "kubectl apply -n $NAMESPACE -f $MANIFEST_URL"

# 2. Esperar a que los pods de Argo CD estén listos
echo "⏳ Waiting for Argo CD components to be ready..."
sg docker -c "kubectl wait --namespace $NAMESPACE \
  --for=condition=available deployment \
  --all \
  --timeout=300s"

# 3. Esperar a que el secreto de la contraseña esté disponible y extraerla
echo "🔑 Waiting for Argo CD admin password secret to be generated..."
PASSWORD=""
while [ -z "$PASSWORD" ]; do
    ENCODED_PASSWORD=$(sg docker -c "kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null" || true)
    if [ -n "$ENCODED_PASSWORD" ]; then
        PASSWORD=$(echo "$ENCODED_PASSWORD" | base64 -d)
    else
        sleep 2
    fi
done

echo "===================================================="
echo "✅ Argo CD successfully installed!"
echo "👤 Username: admin"
echo "🔑 Password: $PASSWORD"
echo "===================================================="