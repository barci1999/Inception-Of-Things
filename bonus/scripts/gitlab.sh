#!/bin/bash

echo "🚀 Configurando e instalando GitLab en el clúster local..."

# 1. Verificar/Crear el namespace 'gitlab' por seguridad
if ! kubectl get namespace gitlab > /dev/null 2>&1; then
    echo "📁 Creando el namespace 'gitlab'..."
    kubectl create namespace gitlab
else
    echo "✅ El namespace 'gitlab' ya existe."
fi

# 2. Añadir y actualizar el repositorio oficial de Helm de GitLab
echo "📦 Añadiendo el repositorio de Helm de GitLab..."
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# 3. Instalar GitLab mediante Helm
# Ajustamos parámetros para entorno local (k3d) y optimizamos recursos desactivando extras pesados
echo "⚙️ Desplegando GitLab (¡Atención: esto puede tardar varios minutos en arrancar por completo!)..."

helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --set global.hosts.domain=local.gitlab.com \
  --set global.hosts.externalIP=127.0.0.1 \
  --set certmanager-issuer.email=admin@iot.com \
  --set prometheus.install=false \
  --set grafana.install=false

echo "✅ ¡Comando de instalación de GitLab lanzado con éxito!"
echo "💡 Para ver el progreso de los pods, ejecuta: kubectl get pods -n gitlab -w"