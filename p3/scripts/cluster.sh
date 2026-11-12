#!/bin/bash

CLUSTER_NAME="iot-cluster"
CONFIG_FILE="confs/k3d-config.yaml"

echo "🔍 Checking Kubernetes cluster status..."
cat "$CONFIG_FILE"

if ! command -v k3d > /dev/null 2>&1; then
    echo "❌ Error: k3d is not installed. Use the command 'make setup' first."
    exit 1
fi

if sg docker -c "k3d cluster list" | grep -q "$CLUSTER_NAME"; then
    echo "✅ Cluster '$CLUSTER_NAME' already exists."
else
    echo "⚙️ Creating Kubernetes cluster with K3d using configuration file..."
    
    if [ -f "$CONFIG_FILE" ]; then
        if ! sg docker -c "k3d cluster create -c \"$CONFIG_FILE\""; then
            echo "❌ Error: k3d could not create cluster '$CLUSTER_NAME'."
            exit 1
        fi
        echo "✅ Cluster '$CLUSTER_NAME' successfully created!"
    else
        echo "❌ Error: Configuration file '$CONFIG_FILE' not found!"
        exit 1
    fi
fi

echo "⏳ Waiting for Kubernetes API server to be fully ready..."
for i in {1..30}; do
    if sg docker -c "kubectl cluster-info" >/dev/null 2>&1; then
        echo "✅ Kubernetes API is ready!"
        break
    fi
    echo "⏳ API server warming up... (Attempt $i/30)"
    sleep 3
done