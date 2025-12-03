# ArgoCD Applications

This directory contains ArgoCD Application manifests for deploying all services.

## Files

- `api-gateway-app.yaml` - API Gateway deployment config
- `booking-service-app.yaml` - Booking Service deployment config
- `frontend-app.yaml` - Frontend deployment config
- `ticket-service-app.yaml` - Ticket Service deployment config
- `user-service-app.yaml` - User Service deployment config

## Before Deploying

Replace `YOUR_ORG` in all files with your actual GitHub organization:

```bash
# Replace YOUR_ORG with your GitHub org name
sed -i 's|YOUR_ORG|your-actual-org|g' *.yaml
```

## Deploy Applications

```bash
# Register the Helm charts repo with ArgoCD (one-time)
argocd repo add https://github.com/YOUR_ORG/argocd-apps-repo \
  --username your-github-username \
  --password your-github-token

# Apply all applications
kubectl apply -f .

# Or apply one at a time
kubectl apply -f api-gateway-app.yaml
```

## Verify

```bash
# Check all applications
argocd app list

# Get details of one app
argocd app get api-gateway
```
