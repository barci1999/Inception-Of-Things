#!/bin/bash

CLUSTER_NAME="iot-cluster"

echo "🧹 Cleaning up Kubernetes cluster..."

# Comprobamos si k3d está instalado antes de intentar borrar
if ! command -v k3d > /dev/null 2>&1; then
    echo "⚠️ k3d is not installed. Nothing to clean for the cluster."
    exit 0
fi

# Comprobamos si el clúster existe antes de borrarlo
if sg docker -c "k3d cluster list" | grep -q "$CLUSTER_NAME"; then
    echo "⚙️ Deleting K3d cluster '$CLUSTER_NAME'..."
    sg docker -c "k3d cluster delete \"$CLUSTER_NAME\""
    echo "✅ Cluster '$CLUSTER_NAME' successfully deleted!"
else
    echo "ℹ️ Cluster '$CLUSTER_NAME' does not exist. Nothing to delete."
fi
if command -v kubectl > /dev/null 2>&1; then
    # Verificamos si el contexto de kubernetes está activo para no dar errores tontos
    if sg docker -c "kubectl cluster-info" > /dev/null 2>&1; then
        echo "🗑️ Cleaning up namespaces..."
        for ns in "${NAMESPACES[@]}"; do
            if sg docker -c "kubectl get namespace "$ns"" > /dev/null 2>&1; then
                echo "⚙️ Deleting namespace '$ns'..."
                sg docker -c "kubectl delete namespace "$ns" --timeout=60s" || true
                echo "✅ Namespace '$ns' deleted."
            else
                echo "ℹ️ Namespace '$ns' does not exist."
            fi
        done
    else
        echo "ℹ️ Kubernetes cluster is not running. Namespaces are already gone."
    fi
fi