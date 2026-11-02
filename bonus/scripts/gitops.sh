#!/bin/bash

# (Nacho) Aplica la Application de Argo CD: vigila el repo público nmagro-r-iot-argocd y despliega la app en dev.
echo "🚀 Applying Argo CD Application (confs/argocd-app.yaml)..."
sg docker -c "kubectl apply -f confs/argocd-app.yaml"
