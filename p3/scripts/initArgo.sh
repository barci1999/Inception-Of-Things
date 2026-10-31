#!/bin/bash

NAMESPACE="argocd"
MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo "🐙 Installing Argo CD into namespace '$NAMESPACE'..."

# 1. Aplicar manifiestos oficiales de Argo CD (dentro de sg docker como prefieres)
if ! sg docker -c "kubectl apply -n $NAMESPACE --server-side --force-conflicts -f $MANIFEST_URL"; then
    echo "❌ Error: could not apply the Argo CD manifests."
    exit 1
fi

# 2. Esperar a que el servidor principal de Argo CD esté disponible mediante bucle de sondeo
echo "⏳ Waiting for Argo CD server to be ready..."
SERVER_READY=false
for i in {1..60}; do
    # Consultamos de forma segura si el deployment ya tiene al menos una réplica lista
    READY_REPLICAS=$(sg docker -c "kubectl get deployment argocd-server -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null" || echo "0")
    
    if [ "$READY_REPLICAS" = "1" ]; then
        echo "✅ Argo CD server is ready!"
        SERVER_READY=true
        break
    fi
    
    echo "⏳ Waiting for Argo CD server pods... (Attempt $i/60)"
    sleep 5
done

if [ "$SERVER_READY" = "false" ]; then
    echo "❌ Error: Argo CD server did not become ready in 5 minutes."
    exit 1
fi

# 3. Esperar a que el secreto de la contraseña esté disponible y extraerla
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