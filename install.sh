#!/bin/bash
set -e

echo "🚀 Installing ArgoCD..."

# Add ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 5.51.6 \
  -f values.yaml \
  --wait \
  --timeout 10m

echo "✅ ArgoCD installed successfully!"

# Get Admin Password
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo ""
echo "🔐 ArgoCD Admin Password: $PASSWORD"

# Get LoadBalancer URL
LB_HOSTNAME=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "🌐 ArgoCD URL: http://$LB_HOSTNAME"
echo "   (It might take a few minutes for DNS to propagate)"
