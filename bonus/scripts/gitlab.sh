#!/bin/bash

NAMESPACE="gitlab"
MANIFEST="confs/gitlab.yaml"

echo "🦊 Installing GitLab (official gitlab-ce image) into namespace '$NAMESPACE'..."
if ! sg docker -c "kubectl apply -f $MANIFEST"; then
    echo "❌ Error: could not apply $MANIFEST."
    exit 1
fi

echo "⏳ Waiting for GitLab to be ready (first start takes 5-10 minutes)..."
if ! sg docker -c "kubectl -n $NAMESPACE rollout status deployment/gitlab --timeout=2400s"; then
    echo "❌ Error: GitLab did not become ready in 20 minutes."
    echo "   Check: kubectl -n $NAMESPACE get pods   and   kubectl -n $NAMESPACE logs deploy/gitlab"
    exit 1
fi

PASSWORD=$(sg docker -c "kubectl -n $NAMESPACE exec deploy/gitlab -- grep '^Password:' /etc/gitlab/initial_root_password" 2>/dev/null | awk '{print $2}')

echo "===================================================="
echo "✅ GitLab is ready!"
echo "🌐 URL: http://localhost"
echo "👤 Username: root"
echo "🔑 Password: ${PASSWORD:-not found (it is only kept for 24 h after the first start)}"
echo "===================================================="
