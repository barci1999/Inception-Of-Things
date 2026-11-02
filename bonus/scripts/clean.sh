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
    # (Nacho) Solo decimos que se ha borrado si k3d no ha fallado
    if ! sg docker -c "k3d cluster delete \"$CLUSTER_NAME\""; then
        echo "❌ Error: k3d could not delete cluster '$CLUSTER_NAME'."
        exit 1
    fi
    echo "✅ Cluster '$CLUSTER_NAME' successfully deleted!"
else
    echo "ℹ️ Cluster '$CLUSTER_NAME' does not exist. Nothing to delete."
fi
# (Nacho) Quitado el bloque que borraba namespaces: no hacía nada (NAMESPACES no existía aquí)
# y al borrar el clúster ya desaparecen sus namespaces, Argo CD y la app.