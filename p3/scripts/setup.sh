#!/bin/bash

echo "🔍 Checking system dependencies..."

# Check and install Docker
if ! command -v docker > /dev/null 2>&1; then
    echo "⚙️ Docker is not installed. Installing..."
    sudo apt-get update -y
    sudo apt-get install -y curl ca-certificates gnupg
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker successfully installed!"
else
    echo "✅ Docker is already installed."
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
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "✅ kubectl successfully installed!"
else
    echo "✅ kubectl is already installed."
fi