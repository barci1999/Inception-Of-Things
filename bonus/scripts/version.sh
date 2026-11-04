#!/bin/bash

# (Nacho) Demo del bonus: cambia la versión de la app (v1 <-> v2) en el GitLab local.
# Uso: bash scripts/version.sh v2
# Hace un commit en root/nmagro-r-iot-argocd (k8s/deployment.yaml) y avisa a Argo CD para que no espere 3 minutos.
NAMESPACE="gitlab"
PROJECT="nmagro-r-iot-argocd"
TAG="$1"

if [ "$TAG" != "v1" ] && [ "$TAG" != "v2" ]; then
    echo "Usage: bash scripts/version.sh v1|v2"
    exit 1
fi

POD=$(sg docker -c "kubectl -n $NAMESPACE get pods -l app=gitlab -o jsonpath='{.items[0].metadata.name}'" 2>/dev/null)
if [ -z "$POD" ]; then
    echo "❌ Error: GitLab is not running."
    exit 1
fi

echo "✏️ Setting wil42/playground:$TAG in GitLab (root/$PROJECT, k8s/deployment.yaml)..."
if ! sg docker -c "kubectl -n $NAMESPACE exec -i $POD -- sh -c 'cat > /tmp/iot-version.rb && gitlab-rails runner /tmp/iot-version.rb'" <<EOF
user = User.find_by_username('root')
project = Project.find_by_full_path('root/$PROJECT') or abort('Project not found: run gitlabRepo.sh first')
path = 'k8s/deployment.yaml'
old = project.repository.blob_at('main', path).data
new = old.gsub(%r{wil42/playground:v[0-9]+}, 'wil42/playground:$TAG')
if new == old
  puts "Already on $TAG"
else
  project.repository.update_file(user, path, new, message: '$TAG', branch_name: 'main')
  puts "Committed: $TAG"
end
EOF
then
    echo "❌ Error: could not change the version in GitLab."
    exit 1
fi

# Igual que el botón "Refresh" de Argo CD
sg docker -c "kubectl -n argocd annotate application wil-playground argocd.argoproj.io/refresh=normal --overwrite" >/dev/null 2>&1
echo "✅ Done. In a few seconds: curl http://localhost:8888/"
