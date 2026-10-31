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
    
    # 1. Instalar dependencias previas
    sudo apt-get update -y
    sudo apt-get install -y curl ca-certificates gnupg

    # 2. Configurar la clave GPG y repositorio oficial de Docker adaptado a Ubuntu/Mint
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      noble stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 3. Actualizar e instalar Docker de forma limpia
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 4. Asegurar que el servicio arranca y se queda activo
    sudo systemctl enable --now docker.service
    sudo systemctl enable --now docker.socket
    
    # 5. Obtener el usuario real de forma segura (evitando que sea root)
    # (Nacho) Si $USER está vacío, lo sacamos con id -un para no quedarnos fuera del grupo docker
    REAL_USER="${SUDO_USER:-${USER:-$(id -un)}}"
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        sudo usermod -aG docker "$REAL_USER"
        echo "👤 Added user '$REAL_USER' to the 'docker' group."
    fi
    
    echo "✅ Docker successfully installed and started!"
else
    echo "✅ Docker is already installed."
    sudo systemctl enable --now docker.service docker.socket >/dev/null 2>&1 || true
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