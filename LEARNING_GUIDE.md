# ArgoCD Installation Guide for Learning (EKS Destroy/Recreate Cycle)

## 🎯 How This Works for Your Learning Scenario

Since you're frequently destroying and recreating EKS clusters, here's the complete flow:

### Installation Flow (One-time setup per EKS cluster)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Create EKS Cluster (via GitHub Actions Terraform workflow)   │
│    → terraform apply                                             │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. Install ArgoCD (via GitHub Actions ArgoCD workflow)          │
│    → helm install argo/argo-cd                                   │
│    → Creates namespace, pods, service                            │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. Get LoadBalancer IP from workflow output                      │
│    → Wait for AWS to assign IP (2-5 minutes)                    │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. Update DuckDNS to point to LoadBalancer IP                    │
│    → argocd007.duckdns.org → 1.2.3.4                            │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. Access ArgoCD via https://argocd007.duckdns.org              │
│    → Login with admin / password (from workflow output)          │
└─────────────────────────────────────────────────────────────────┘
```

### Destroy & Recreate Flow (What happens when you learn and retry)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Run ArgoCD Uninstall Workflow                                 │
│    → helm uninstall argo/argo-cd                                │
│    → kubectl delete namespace argocd                             │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. Destroy EKS Cluster (via Terraform workflow)                  │
│    → terraform destroy                                           │
│    → Removes all K8s resources, including ArgoCD                │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. [LEARN & EXPERIMENT - make changes]                           │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. Create NEW EKS Cluster (terraform apply again)               │
│    → New cluster, new LoadBalancer, new IPs                     │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. Install ArgoCD on NEW cluster (same workflow!)                │
│    → Gets NEW LoadBalancer IP                                    │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. Update DuckDNS with NEW IP (point to new LoadBalancer)       │
│    → argocd007.duckdns.org → 5.6.7.8 (different IP)            │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. Access ArgoCD on NEW cluster (same URL!)                      │
│    → https://argocd007.duckdns.org works again                  │
│    → But it's a FRESH ArgoCD (no previous config)               │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Step-by-Step Instructions

### First Time Setup

1. **Create your EKS cluster:**
   ```
   GitHub → Actions → Terraform Infrastructure 
   → Run workflow → action: "apply" → Run workflow
   ```
   Wait for completion (~15-20 min)

2. **Install ArgoCD:**
   ```
   GitHub → Actions → ArgoCD Deployment 
   → Run workflow → action: "install" → Run workflow
   ```
   Wait for completion (2-3 min)

3. **Get LoadBalancer IP from workflow output:**
   - View the workflow run
   - Look for section: "NEXT STEPS FOR YOUR LEARNING SETUP"
   - Copy the LoadBalancer IP (e.g., `1.2.3.4`)

4. **Update DuckDNS:**
   - Go to https://www.duckdns.org
   - Sign in with your credentials
   - Find the `argocd007` domain
   - Paste the LoadBalancer IP in the IP field
   - Click "update"
   - Wait 5-10 minutes for DNS to propagate

5. **Access ArgoCD:**
   ```
   https://argocd007.duckdns.org
   Username: admin
   Password: [from workflow output above]
   ```

### When You Destroy & Recreate EKS

#### Before destroying:

```bash
# Option 1: Use GitHub Actions (recommended)
GitHub → Actions → ArgoCD Deployment 
→ Run workflow → action: "uninstall" → Run workflow

# Option 2: Manual cleanup (if needed)
kubectl delete namespace argocd
```

#### Then destroy EKS:

```
GitHub → Actions → Terraform Infrastructure 
→ Run workflow → action: "destroy" → Run workflow
```

#### When you recreate:

1. Create NEW EKS cluster (same terraform apply)
2. Install ArgoCD again (same workflow, "install" action)
3. **Get the NEW LoadBalancer IP** (it will be different!)
4. **Update DuckDNS with the NEW IP**
5. Access ArgoCD via same URL (argocd007.duckdns.org)

## 🔄 Why This Architecture Works

| Aspect | Benefit for Learning |
|--------|----------------------|
| **GitHub Actions** | No need to run commands locally. Portable across devices. |
| **DuckDNS** | Free, stable domain. Single URL even when IPs change. |
| **Helm** | Idempotent - same command works for fresh install or upgrade. |
| **LoadBalancer** | AWS assigns public IP automatically. No manual config. |

## ❓ Common Questions

### Q: Why do I need to update DuckDNS every time I recreate EKS?

**A:** Every time AWS creates a new LoadBalancer, it assigns a different IP address. DuckDNS is the bridge:
- DuckDNS domain: `argocd007.duckdns.org` (stays the same)
- DuckDNS points to: `LoadBalancer IP` (changes when EKS is recreated)
- Your browser: Always uses `argocd007.duckdns.org` (never changes)

### Q: Do I lose ArgoCD configuration when I destroy EKS?

**A:** Yes, completely. ArgoCD is installed inside the EKS cluster:
- Destroy EKS → ArgoCD is deleted
- Create new EKS → ArgoCD is brand new (fresh)
- This is fine for learning! You can practice setting it up each time.

### Q: Can I backup ArgoCD configuration?

**A:** Yes, for later learning:
- Backup: `kubectl get all -n argocd -o yaml > argocd-backup.yaml`
- Restore: `kubectl apply -f argocd-backup.yaml`
- But for now, focus on the fresh install each time.

### Q: How long does each step take?

| Step | Time |
|------|------|
| Create EKS (terraform apply) | 15-20 min |
| Install ArgoCD | 2-3 min |
| Get LoadBalancer IP | 2-5 min (wait for AWS) |
| DNS propagation | 5-10 min |
| **Total first time** | ~35 min |
| Destroy EKS | 10-15 min |
| Reinstall ArgoCD | ~5 min |
| **Total cycle** | ~20 min (after destroy) |

### Q: What if LoadBalancer IP doesn't appear?

**A:** AWS sometimes takes longer:
1. Wait 5 more minutes
2. Manually check:
   ```bash
   kubectl get svc -n argocd argocd-server
   ```
3. If still blank, check if nginx-ingress is installed (required for ingress)

### Q: Can I access ArgoCD without DuckDNS?

**A:** Yes, for local testing:
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
# Then visit: http://localhost:8080
```

## 🚀 Quick Reference Commands

```bash
# Check if ArgoCD is running
kubectl get pods -n argocd

# Check LoadBalancer IP
kubectl get svc -n argocd argocd-server

# Get fresh admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward (for local access)
kubectl port-forward -n argocd svc/argocd-server 8080:443

# View ArgoCD logs
kubectl logs -n argocd deployment/argocd-server

# Delete everything (if you're stuck)
kubectl delete namespace argocd
```

## 📚 Learning Path

1. **Phase 1:** Install once, explore ArgoCD UI
2. **Phase 2:** Add your GitHub repos as ArgoCD Applications
3. **Phase 3:** Deploy your booking app via ArgoCD
4. **Phase 4:** Experiment with GitOps (sync, diff, rollback)
5. **Repeat:** Destroy, recreate, learn more each cycle

Happy learning! 🎓
