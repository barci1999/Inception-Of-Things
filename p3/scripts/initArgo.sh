#!/bin/bash

NAMESPACE="argocd"
MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo "🐙 Installing Argo CD into namespace '$NAMESPACE'..."

# 1. Aplicar manifiestos oficiales de Argo CD
# (Nacho) Si falla la instalación, paramos aquí en vez de seguir esperando
if ! sg docker -c "kubectl apply -n $NAMESPACE --server-side --force-conflicts -f $MANIFEST_URL"; then
    echo "❌ Error: could not apply the Argo CD manifests."
    exit 1
fi

# 2. Esperar a que los pods de Argo CD estén listos
echo "⏳ Waiting for Argo CD components to be ready..."
if ! sg docker -c "kubectl wait --namespace $NAMESPACE \
  --for=condition=available deployment \
  --all \
  --timeout=300s"; then
    echo "❌ Error: Argo CD components did not become ready in 5 minutes."
    exit 1
fi

# 3. Esperar a que el secreto de la contraseña esté disponible y extraerla
# (Nacho) Como mucho 2 minutos (60 intentos x 2 s), para no quedarnos esperando para siempre
echo "🔑 Waiting for Argo CD admin password secret to be generated..."
PASSWORD=""
for _ in $(seq 1 60); do
    ENCODED_PASSWORD=$(sg docker -c "kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null" || true)
    if [ -n "$ENCODED_PASSWORD" ]; then
        PASSWORD=$(echo "$ENCODED_PASSWORD" | base64 -d)
        break
    fi
    sleep 2
done
if [ -z "$PASSWORD" ]; then
    echo "❌ Error: the Argo CD admin password secret was not created."
    exit 1
fi

echo "===================================================="
echo "✅ Argo CD successfully installed!"
echo "👤 Username: admin"
echo "🔑 Password: $PASSWORD"
echo "===================================================="