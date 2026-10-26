#!/bin/bash

# Lista de namespaces necesarios para el proyecto
NAMESPACES=("argocd" "dev")

echo "📁 Checking and creating required namespaces..."

for ns in "${NAMESPACES[@]}"; do
    if ! sg docker -c "kubectl get namespace "$ns"" > /dev/null 2>&1; then
        echo "⚙️ Creating namespace '$ns'..."
        sg docker -c "kubectl create namespace "$ns""
        echo "✅ Namespace '$ns' successfully created!"
    else
        echo "ℹ️ Namespace '$ns' already exists."
    fi
done

echo "✨ All namespaces are ready!"