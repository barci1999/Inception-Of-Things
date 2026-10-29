#!/bin/bash

CLUSTER_NAME="iot-cluster"
CONFIG_FILE="confs/k3d-config.yaml"

echo "🔍 Checking Kubernetes cluster status..."
cat "$CONFIG_FILE"

# Check if k3d is installed
if ! command -v k3d > /dev/null 2>&1; then
    echo "❌ Error: k3d is not installed. Use the command 'make setup' first."
    exit 1
fi

# Check if the cluster already exists (protegido con sg docker por si acaso)
if sg docker -c "k3d cluster list" | grep -q "$CLUSTER_NAME"; then
    echo "✅ Cluster '$CLUSTER_NAME' already exists."
else
    echo "⚙️ Creating Kubernetes cluster with K3d using configuration file..."
    
    # Check if config file exists before creating
    if [ -f "$CONFIG_FILE" ]; then
        # Forzamos la ejecución con los permisos del grupo docker actualizados
        sg docker -c "k3d cluster create -c \"$CONFIG_FILE\""
        echo "✅ Cluster '$CLUSTER_NAME' successfully created!"
    else
        echo "❌ Error: Configuration file '$CONFIG_FILE' not found!"
        exit 1
    fi
fi