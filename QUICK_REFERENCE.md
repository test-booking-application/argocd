# Jenkins CD → ArgoCD Migration - Quick Reference

## 🎯 Key Differences

| Aspect | Jenkins CD | ArgoCD |
|--------|-----------|--------|
| **Trigger** | Manual job run | Git push / automatic |
| **Configuration** | Jenkins UI parameters | Git repository (values.yaml) |
| **Infrastructure** | Requires Jenkins running 24/7 | Uses cluster resources |
| **Truth Source** | Git + Jenkins parameters | Git only |
| **Observability** | Jenkins logs | ArgoCD UI + git history |
| **Rollback** | Manual retry with old tag | Git revert |
| **Cost** | Separate Jenkins server | Zero (uses EKS) |

## 📋 Migration Steps

### Phase 1: Setup (One-time)
```bash
# 1. Create new GitHub repo for ArgoCD apps
mkdir argocd-apps-repo
cd argocd-apps-repo

# 2. Copy your Helm charts there
cp -r ../charts/* ./

# 3. Create Application manifests (see examples/)

# 4. Push to GitHub
git push origin main

# 5. Register repo with ArgoCD (via UI or CLI)
```

### Phase 2: Create Applications (One per service)
```bash
# In argocd-apps-repo/argocd-applications/
kubectl apply -f api-gateway-app.yaml
kubectl apply -f booking-service-app.yaml
# ... etc
```

### Phase 3: Test Manual Sync
```
ArgoCD UI:
  Applications → api-gateway → SYNC
```

### Phase 4: Enable Auto-Sync
```yaml
# Update Application manifest
syncPolicy:
  automated:
    prune: true
    selfHeal: true

# Commit and push
git push origin main
```

### Phase 5: Update CI Pipeline
```yaml
# In your build workflow (build-api-gateway.yml)
- name: Update ArgoCD Repo
  run: |
    # Update values.yaml with new image tag
    sed -i "s/tag: .*/tag: $NEW_TAG/" values.yaml
    # Push to argocd-apps-repo
    git push
```

## 🚀 Deployment Comparison

### OLD: Using Jenkins CD Job
```bash
# 1. Build image (CI - GitHub Actions)
$ github-actions → ECR

# 2. Manual deploy (CD - Jenkins)
$ jenkins-ui → Run Job → Select IMAGE_TAG → Deploy

# 3. Result: Takes 5-10 minutes, manual steps
```

### NEW: Using ArgoCD
```bash
# 1. Build image (CI - GitHub Actions)
$ github-actions → ECR → Update git

# 2. Automatic deploy (CD - ArgoCD)
$ git-push → ArgoCD detects → Auto-syncs → Deployed

# 3. Result: Takes 3-5 minutes, fully automatic
```

## 📁 Example File Structure

```
argocd-apps-repo/
├── api-gateway/
│   ├── Chart.yaml
│   ├── values.yaml          ← Update image tag here
│   └── templates/
├── booking-service/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── frontend/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── ticket-service/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── user-service/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
└── argocd-applications/
    ├── api-gateway-app.yaml
    ├── booking-service-app.yaml
    ├── frontend-app.yaml
    ├── ticket-service-app.yaml
    └── user-service-app.yaml
```

## ⚡ Quick Commands

### Register ArgoCD Repo
```bash
argocd repo add https://github.com/YOUR_ORG/argocd-apps-repo \
  --username YOUR_USERNAME \
  --password YOUR_TOKEN
```

### List Applications
```bash
argocd app list
```

### Sync Manually
```bash
argocd app sync api-gateway
```

### Get Application Status
```bash
argocd app get api-gateway
```

### View App Details
```bash
kubectl get application -n argocd
```

## 🔄 Rollback Process

### Old (Jenkins)
```bash
# Find old tag in Jenkins logs
# Manually run Jenkins job with old tag
# Hope it works
```

### New (ArgoCD + Git)
```bash
# 1. View git history
git log api-gateway/values.yaml

# 2. Revert to previous version
git revert HEAD

# 3. Push
git push

# 4. ArgoCD automatically rolls back
```

## 🎓 Learning Path

```
Week 1:
├─ Install ArgoCD
├─ Create 1 Application (api-gateway)
└─ Deploy manually via UI sync

Week 2:
├─ Update CI to push to argocd-apps-repo
├─ Test auto-deployment
└─ Create Applications for all services

Week 3:
├─ Enable auto-sync
├─ Practice rollbacks via git
└─ Explore ArgoCD advanced features

Week 4+:
├─ Multi-environment (dev/staging/prod)
├─ ApplicationSets for multiple apps
├─ Notifications & integrations
└─ Self-healing & monitoring
```

## 🚨 Common Issues & Solutions

### Issue: ArgoCD shows "OutOfSync"
**Solution:** This is normal! It means git != cluster state
```bash
# Either:
1. Click SYNC in ArgoCD UI
2. Or: argocd app sync api-gateway
3. Or: Let auto-sync handle it (if enabled)
```

### Issue: Deployment not updating after git push
**Solution:** ArgoCD checks every 3 minutes (default)
```bash
# Force immediate check:
argocd app refresh api-gateway

# Or enable webhooks for instant detection
```

### Issue: Need to rollback
**Solution:** Simplest GitOps way
```bash
git revert <commit-hash>
git push
# ArgoCD automatically deploys previous version
```

## ✅ Ready to Deploy?

When you're ready:
1. ✅ Ensure ArgoCD is installed and running
2. ✅ Create argocd-apps-repo with your Helm charts
3. ✅ Create Application manifests (see examples/)
4. ✅ Register repo with ArgoCD
5. ✅ Test manual sync
6. ✅ Update CI workflow
7. ✅ Enable auto-sync
8. ✅ Remove Jenkins CD jobs (keep CI)

See `CD_PIPELINE_MIGRATION.md` for detailed steps!
