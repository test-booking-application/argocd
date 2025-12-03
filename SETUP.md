# Enable ArgoCD using GitHub Actions

## Prerequisites

- GitHub repository with AWS credentials configured as secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- EKS cluster already created (via Terraform)
- Your code pushed to GitHub

## How to Enable ArgoCD

### Step 1: Verify AWS Credentials in GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Ensure these secrets exist:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

If they don't exist, add them with your AWS credentials.

### Step 2: Run ArgoCD Installation Workflow

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **ArgoCD Deployment** workflow
4. Click **Run workflow**
5. Select **install** from the action dropdown
6. Click **Run workflow**

The workflow will:
- Configure AWS credentials
- Connect to your EKS cluster
- Install ArgoCD using Helm
- Display the admin password and access URL

### Step 3: Access ArgoCD

Once the workflow completes:

1. **Get the ArgoCD URL from the workflow logs:**
   - In GitHub Actions, view the workflow run
   - Look for "ArgoCD URL" in the output
   - URL format: `http://<LoadBalancer-IP-or-Hostname>`

2. **Get the Admin Password:**
   - Find "ArgoCD Admin Password" in the workflow logs
   - Save it securely

3. **Login to ArgoCD:**
   - Open the URL in your browser
   - Username: `admin`
   - Password: (from the logs above)

### Step 4: Access via CLI (Optional)

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Set the ArgoCD server address
export ARGOCD_SERVER=<your-argocd-url>

# Login
argocd login $ARGOCD_SERVER

# List applications
argocd app list
```

## How to Uninstall ArgoCD

1. Go to GitHub repository → **Actions**
2. Select **ArgoCD Deployment** workflow
3. Click **Run workflow**
4. Select **uninstall**
5. Click **Run workflow**

## Troubleshooting

### LoadBalancer IP Not Showing

If the workflow times out waiting for the LoadBalancer:
- AWS can take 5-10 minutes to assign an IP/hostname
- Check manually:
  ```bash
  kubectl get svc -n argocd argocd-server
  ```

### Cannot Connect to ArgoCD

1. Verify the service is running:
   ```bash
   kubectl get pods -n argocd
   ```

2. Check the LoadBalancer status:
   ```bash
   kubectl get svc -n argocd
   ```

3. Try port-forwarding if LoadBalancer is not working:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   # Then access: http://localhost:8080
   ```

## Next Steps

After ArgoCD is installed:

1. **Create Applications** - Connect your GitHub repos
2. **Deploy Services** - Use ArgoCD to deploy booking app, API gateway, etc.
3. **Monitor** - Set up Prometheus/Grafana for metrics
4. **Automate** - Configure webhooks for GitOps workflows

## Configuration

The ArgoCD deployment uses values from `tools/cicd/argocd/values.yaml`. To customize:

1. Edit `tools/cicd/argocd/values.yaml`
2. Push changes to GitHub
3. Re-run the workflow with `install` action

Common customizations:
- Enable TLS
- Configure ingress
- Set resource limits
- Enable notifications
