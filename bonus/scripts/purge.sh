#!/bin/bash

echo "🧹 Starting system purge (uninstalling Docker, K3d, and kubectl)..."

# Uninstall Docker
# --- Desinstalación de Helm ---


# 1. Eliminar el binario de Helm (si existe)
if command -v helm > /dev/null 2>&1; then
    # Por lo general el script oficial lo coloca en /usr/local/bin/helm
    sudo rm -f $(which helm)
    echo "🗑️ Removing helm binary..."
else
    echo "ℹ️ helm was not installed."
fi

# 2. Limpiar directorios de caché y configuración locales (opcional pero recomendado)
rm -rf ~/.cache/helm
rm -rf ~/.config/helm
rm -rf ~/.local/share/helm

echo "✅ helm removed."
if command -v docker > /dev/null 2>&1; then
    echo "🗑️ Uninstalling Docker..."
    sudo systemctl stop docker.service docker.socket containerd.service 2>/dev/null || true
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-doc docker-compose || true
    sudo rm -rf /var/lib/docker /etc/docker /var/run/docker.sock /var/lib/containerd
    echo "✅ Docker uninstalled."
else
    echo "ℹ️ Docker was not installed."
fi

# Remove K3d
if command -v k3d > /dev/null 2>&1; then
    echo "🗑️ Removing K3d binary..."
    sudo rm -f $(which k3d) || sudo rm -f /usr/local/bin/k3d || true
    echo "✅ K3d removed."
else
    echo "ℹ️ K3d was not installed."
fi

# Remove kubectl
if command -v kubectl > /dev/null 2>&1; then
    echo "🗑️ Removing kubectl binary..."
    sudo rm -f /usr/local/bin/kubectl
    echo "✅ kubectl removed."
else
    echo "ℹ️ kubectl was not installed."
fi

echo "✨ Purge complete! The virtual machine is back to a pristine state."