#!/bin/bash

echo "🔍 Checking system dependencies..."

# Check and install Docker
if ! command -v docker > /dev/null 2>&1; then
    echo "⚙️ Docker is not installed. Installing..."
    
    # Esperar a que apt se libere si hay actualizaciones en segundo plano
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        echo "🔒 Waiting for background system updates to finish..."
        sleep 5
    done
    
    sudo apt-get update -y
    sudo apt-get install -y curl ca-certificates gnupg
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    
    # 1. Asegurar que el servicio arranca y se queda activo
    sudo systemctl enable --now docker
    
    # 2. Obtener el usuario real de forma segura (evitando que sea root)
    # (Nacho) Si $USER está vacío, lo sacamos con id -un para no quedarnos fuera del grupo docker
    REAL_USER="${SUDO_USER:-${USER:-$(id -un)}}"
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        sudo usermod -aG docker "$REAL_USER"
        echo "👤 Added user '$REAL_USER' to the 'docker' group."
    fi
    
    rm get-docker.sh
    echo "✅ Docker successfully installed and started!"
    echo "⚠️ NOTE: If you run scripts immediately in this same terminal session,"
    echo "   please run 'newgrp docker' or open a new terminal first."
fi

# Check and install K3d
if ! command -v k3d > /dev/null 2>&1; then
    echo "⚙️ K3d is not installed. Installing..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "✅ K3d successfully installed!"
else
    echo "✅ K3d is already installed."
fi

# Check and install kubectl
if ! command -v kubectl > /dev/null 2>&1; then
    echo "⚙️ kubectl is not installed. Installing..."
    # (Nacho) kubectl para el procesador de la máquina (amd64 en Intel/AMD, arm64 en ARM)
    ARCH=$(dpkg --print-architecture)
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "✅ kubectl successfully installed!"
else
    echo "✅ kubectl is already installed."
fi