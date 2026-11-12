#!/bin/bash

echo "🔍 Checking system dependencies..."

if ! command -v docker > /dev/null 2>&1; then
    echo "⚙️ Docker is not installed. Installing..."
    
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        echo "🔒 Waiting for background system updates to finish..."
        sleep 5
    done
    
    sudo apt-get update -y
    sudo apt-get install -y curl ca-certificates gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      noble stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    sudo systemctl enable --now docker.service
    sudo systemctl enable --now docker.socket
    
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

if ! command -v k3d > /dev/null 2>&1; then
    echo "⚙️ K3d is not installed. Installing..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "✅ K3d successfully installed!"
else
    echo "✅ K3d is already installed."
fi

if ! command -v kubectl > /dev/null 2>&1; then
    echo "⚙️ kubectl is not installed. Installing..."
    ARCH=$(dpkg --print-architecture)
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "✅ kubectl successfully installed!"
else
    echo "✅ kubectl is already installed."
fi