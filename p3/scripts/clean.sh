#!/bin/bash

CLUSTER_NAME="iot-cluster"

echo "🧹 Cleaning up Kubernetes cluster..."

if ! command -v k3d > /dev/null 2>&1; then
    echo "⚠️ k3d is not installed. Nothing to clean for the cluster."
    exit 0
fi

if sg docker -c "k3d cluster list" | grep -q "$CLUSTER_NAME"; then
    echo "⚙️ Deleting K3d cluster '$CLUSTER_NAME'..."
    if ! sg docker -c "k3d cluster delete \"$CLUSTER_NAME\""; then
        echo "❌ Error: k3d could not delete cluster '$CLUSTER_NAME'."
        exit 1
    fi
    echo "✅ Cluster '$CLUSTER_NAME' successfully deleted!"
else
    echo "ℹ️ Cluster '$CLUSTER_NAME' does not exist. Nothing to delete."
fi
