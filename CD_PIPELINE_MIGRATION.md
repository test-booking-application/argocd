# Replacing Jenkins CD Pipeline with ArgoCD

## 🔄 Old vs New Architecture

### OLD: Jenkins-Based CD Pipeline
```
Code Changes
    ↓
GitHub Push Event
    ↓
Jenkins Webhook Triggered
    ↓
Jenkins runs Jenkinsfile.cd
    ↓
Jenkins manually updates Helm values
    ↓
Jenkins runs: helm upgrade --install
    ↓
Application deployed to EKS
```

**Problems:**
- Manual step to trigger deployment
- Jenkins must be running 24/7
- Hard to track what's deployed vs what's in git
- Rollback requires manual intervention

### NEW: ArgoCD GitOps Pipeline
```
Code Changes → Push to Git
    ↓
Git Repository (source of truth)
    ↓
ArgoCD continuously monitors repo
    ↓
ArgoCD detects changes
    ↓
ArgoCD automatically syncs
    ↓
Application deployed to EKS
    ↓
ArgoCD continuously monitors actual state
    ↓
If state drifts → auto-correct (optional)
```

**Benefits:**
- ✅ Declarative: All infrastructure/apps defined in git
- ✅ Automatic: Changes sync automatically
- ✅ Observable: See what's deployed anytime
- ✅ Auditable: Git history = deployment history
- ✅ Safe: Manual approval gates optional
- ✅ Rollback: Just revert git commit

## 📂 Project Structure (New with ArgoCD)

Create a new Git repository for all your Kubernetes manifests:

```
argocd-apps-repo/
├── README.md
├── api-gateway/
│   ├── kustomization.yaml
│   └── values.yaml
├── booking-service/
│   ├── kustomization.yaml
│   └── values.yaml
├── frontend/
│   ├── kustomization.yaml
│   └── values.yaml
├── user-service/
│   ├── kustomization.yaml
│   └── values.yaml
├── ticket-service/
│   ├── kustomization.yaml
│   └── values.yaml
└── argocd-applications/
    ├── api-gateway-app.yaml
    ├── booking-service-app.yaml
    ├── frontend-app.yaml
    ├── user-service-app.yaml
    └── ticket-service-app.yaml
```

## 🚀 How to Replace Jenkins CD with ArgoCD

### Step 1: Remove Jenkins Dependency

Old way (Jenkins):
```bash
# Manually trigger Jenkins
curl -X POST "https://jenkins-url/job/api-gateway-cd/buildWithParameters?IMAGE_TAG=abc123"
```

New way (Git):
```bash
# Just update git, ArgoCD does the rest
git commit -m "Update api-gateway to v1.2.3"
git push origin main
# ArgoCD automatically detects change within 3 minutes
```

### Step 2: Create ArgoCD Applications

Instead of Jenkins calling `helm upgrade`, create ArgoCD Application manifests:

**Example: api-gateway-app.yaml**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: api-gateway
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_ORG/argocd-apps-repo
    targetRevision: main
    path: api-gateway
    helm:
      releaseName: api-gateway
      values: |
        image:
          repository: 044302809167.dkr.ecr.us-east-1.amazonaws.com/ticket-booking/api-gateway
          tag: latest
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true        # Delete resources not in git
      selfHeal: true     # Auto-sync if cluster state drifts
    syncOptions:
    - CreateNamespace=true
```

### Step 3: Update Your Values Files

Move your Helm values from Jenkins parameters to Git:

**Old (Jenkins Parameter):**
```bash
# Pass IMAGE_TAG as Jenkins parameter
helm upgrade --install api-gateway ./charts/api-gateway \
  --set image.tag=abc123  # Jenkins parameter
```

**New (Git-based):**

File: `api-gateway/values.yaml`
```yaml
image:
  repository: 044302809167.dkr.ecr.us-east-1.amazonaws.com/ticket-booking/api-gateway
  tag: v1.2.3  # Update this when you want new version deployed
  pullPolicy: IfNotPresent

replicaCount: 2

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### Step 4: Update CI Pipeline (Keep GitHub Actions)

Your GitHub Actions CI pipeline stays the same:
1. Build Docker image
2. Push to ECR
3. **NEW:** Update git repo with new image tag
4. ArgoCD automatically deploys

**Example: Updated CI Workflow**
```yaml
# .github/workflows/build-api-gateway.yml
name: Build API Gateway

on:
  push:
    branches: [main]
    paths:
      - 'api-gateway/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and Push to ECR
        run: |
          # ... build docker image ...
          # ... push to ECR ...
          IMAGE_TAG=$(git rev-parse --short HEAD)
          echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_OUTPUT
      
      - name: Update ArgoCD Apps Repo
        run: |
          # Clone argocd-apps-repo
          git clone https://github.com/YOUR_ORG/argocd-apps-repo.git
          
          # Update api-gateway values.yaml
          sed -i "s/tag: .*/tag: ${{ steps.build.outputs.IMAGE_TAG }}/" \
            argocd-apps-repo/api-gateway/values.yaml
          
          # Push changes
          cd argocd-apps-repo
          git config user.email "ci@github.com"
          git config user.name "GitHub CI"
          git add .
          git commit -m "Update api-gateway image tag to ${{ steps.build.outputs.IMAGE_TAG }}"
          git push origin main
```

## 📋 Deployment Flow Comparison

### Jenkins CD (Manual Steps per Deploy)
```
Developer
    ↓
Runs Jenkins job manually
    ↓
Selects IMAGE_TAG parameter
    ↓
Jenkins runs helm upgrade
    ↓
Wait 2-5 minutes
    ↓
Check if deployment worked
    ↓
If failed, debug logs, retry
```

### ArgoCD (Automatic, Git-based)
```
Developer
    ↓
Updates values.yaml in git
    ↓
Commits and pushes
    ↓
ArgoCD detects change (within 3 min)
    ↓
ArgoCD syncs automatically
    ↓
Deployment happens instantly
    ↓
Can see in ArgoCD UI in real-time
```

## 🔐 Security & Control

### Manual Sync (When You Want Control)
```yaml
syncPolicy:
  # automated: disabled (manual only)
  syncOptions:
  - CreateNamespace=true
```

Then manually sync from ArgoCD UI:
```
ArgoCD → Application → api-gateway → SYNC
```

### Automated Sync (Full GitOps)
```yaml
syncPolicy:
  automated:
    prune: true      # Auto-prune
    selfHeal: true   # Auto-correct drift
```

### Require Approval (Optional)
```yaml
syncPolicy:
  automated:
    prune: false
    selfHeal: false
  # Add webhook notification to notify before sync
```

## ✅ Migration Checklist

- [ ] Create new GitHub repo for `argocd-apps-repo`
- [ ] Move your Helm charts there
- [ ] Create ArgoCD Application manifests (one per service)
- [ ] Update CI pipeline to update git instead of calling Jenkins
- [ ] Test ArgoCD deployment (manual sync first)
- [ ] Enable automated sync once confident
- [ ] Remove Jenkins CD jobs (keep CI jobs for building)
- [ ] Document new deployment process for team

## 🎯 Step-by-Step Migration Guide

### 1. Create ArgoCD Apps Repository

```bash
# Create new repo
mkdir argocd-apps-repo
cd argocd-apps-repo
git init
git remote add origin https://github.com/YOUR_ORG/argocd-apps-repo.git

# Copy Helm charts
cp -r ../test-booking-application/api-gateway/charts/api-gateway ./api-gateway/
cp -r ../test-booking-application/booking-service/charts/booking-service ./booking-service/
cp -r ../test-booking-application/frontend/charts/frontend ./frontend/
# ... repeat for all services

git add .
git commit -m "Initial: Helm charts for ArgoCD"
git push -u origin main
```

### 2. Create ArgoCD Application Manifests

Place in `argocd-applications/` folder in the repo above.

### 3. Register Repository with ArgoCD

From ArgoCD UI:
```
Settings → Repositories → Connect Repo
```

Or via CLI:
```bash
argocd repo add https://github.com/YOUR_ORG/argocd-apps-repo \
  --username git-username \
  --password git-token \
  --insecure-skip-server-verification
```

### 4. Create Applications in ArgoCD

From ArgoCD UI:
```
Applications → New App
→ Fill in repo URL, path, destination
```

Or apply manifests:
```bash
kubectl apply -f argocd-applications/
```

### 5. Test Manual Sync

```
ArgoCD UI → Application → SYNC button
```

### 6. Enable Automated Sync

Update Application manifests to enable auto-sync, commit to git.

### 7. Decommission Jenkins

Once stable:
```bash
# Keep Jenkinsfile (for reference)
# But remove Jenkinsfile.cd (no longer needed)
# Remove Jenkins CD jobs
```

## 🚨 Rollback with ArgoCD

### Old Way (Jenkins - Manual)
```bash
# Find previous image tag
# Manually trigger Jenkins with old tag
# Hope it works
```

### New Way (ArgoCD - Git)
```bash
# View git history
git log api-gateway/values.yaml

# Revert to previous version
git revert HEAD

# Push
git push origin main

# ArgoCD automatically deploys old version
# Done in <1 minute
```

## 📊 Monitoring & Observability

ArgoCD UI shows:
- ✅ All applications status
- ✅ What's running vs what's in git
- ✅ Sync history
- ✅ Resource tree
- ✅ Logs
- ✅ Events

## ❓ FAQ

**Q: Do I need to keep Jenkins?**  
A: No for CD. Keep it for CI (building images) if you use Jenkins for that. Otherwise use GitHub Actions.

**Q: What if I need manual approval before deploy?**  
A: Set `syncPolicy: {}` (no automated), manually sync from ArgoCD UI or API.

**Q: How often does ArgoCD check for changes?**  
A: Default every 3 minutes. Configurable. Can also use webhooks for instant detection.

**Q: Can I deploy to multiple namespaces?**  
A: Yes, create multiple Applications, each pointing to different namespace in `spec.destination`.

**Q: What about secrets?**  
A: Store encrypted in git using sealed-secrets or external-secrets operator. Never plain text!

## 🎓 Next Steps for Your Learning

1. Keep building with GitHub Actions (CI - build images)
2. Add GitHub Actions workflow to update git repo with new image tags
3. Let ArgoCD handle deployment (CD - deploy to cluster)
4. Practice rollback by reverting git commits
5. Enable auto-sync once comfortable
6. Explore advanced ArgoCD features: multi-repo, kustomize, helm hooks, etc.
