#!/bin/bash

NAMESPACES=("argocd" "dev")

echo "📁 Checking and creating required namespaces..."

for ns in "${NAMESPACES[@]}"; do
    if ! sg docker -c "kubectl get namespace "$ns"" > /dev/null 2>&1; then
        echo "⚙️ Creating namespace '$ns'..."
        if ! sg docker -c "kubectl create namespace "$ns""; then
            echo "❌ Error: could not create namespace '$ns'. Is the cluster running?"
            exit 1
        fi
        echo "✅ Namespace '$ns' successfully created!"
    else
        echo "ℹ️ Namespace '$ns' already exists."
    fi
done

echo "✨ All namespaces are ready!"