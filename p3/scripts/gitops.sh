#!/bin/bash

echo "🚀 Applying Argo CD Application (confs/argocd-app.yaml)..."
sg docker -c "kubectl apply -f confs/argocd-app.yaml"
