#!/bin/bash

echo "🧹 Starting system purge (uninstalling Docker, K3d, and kubectl)..."

# Uninstall Docker
if command -v docker > /dev/null 2>&1; then
echo "🗑️ Uninstalling Docker..."
    sudo systemctl stop docker || true
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras docker.io docker-engine || true
    sudo apt-get autoremove -y --purge || true
    sudo rm -rf /var/lib/docker /etc/docker /var/run/docker.sock || true
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