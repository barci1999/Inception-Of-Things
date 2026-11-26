#!/bin/bash

NAMESPACE="argocd"
MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo "🐙 Installing Argo CD into namespace '$NAMESPACE'..."

if ! sg docker -c "kubectl apply -n $NAMESPACE --server-side --force-conflicts -f $MANIFEST_URL"; then
    echo "❌ Error: could not apply the Argo CD manifests."
    exit 1
fi

echo "⏳ Waiting for Argo CD server to be ready..."
SERVER_READY=false
for i in {1..60}; do
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
