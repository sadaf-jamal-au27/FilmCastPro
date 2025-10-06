# Email Notifications Setup Guide

Configure email notifications for your GitOps pipeline deployments.

---

## 📧 Notification Options

You can get email notifications at different stages:

1. **GitHub Actions** - Build/deployment status
2. **ArgoCD** - Sync status and health alerts
3. **Kubernetes** - Pod failures and errors

---

## 🔔 Option 1: GitHub Actions Email Notifications

### Method A: Built-in GitHub Notifications (Easiest)

**Setup:**
1. Go to: https://github.com/settings/notifications
2. Enable "Actions" under Email notification preferences
3. You'll get emails for:
   - ✅ Workflow runs
   - ❌ Failed builds
   - ⚠️ Warnings

**Configure per repository:**
1. Go to: https://github.com/sadaf-jamal-au27/FilmCastPro
2. Click "Watch" → "Custom"
3. Check "Actions"

### Method B: Custom Email Action (More Control)

Add to `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy to EKS

on:
  push:
    branches: [main]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      # ... existing steps ...
      
      - name: Send success email
        if: success()
        uses: dawidd6/action-send-mail@v3
        with:
          server_address: smtp.gmail.com
          server_port: 465
          username: ${{ secrets.EMAIL_USERNAME }}
          password: ${{ secrets.EMAIL_PASSWORD }}
          subject: "✅ Deployment Success - FilmCastPro"
          to: jamalsadaf3@gmail.com
          from: GitHub Actions
          body: |
            Deployment completed successfully!
            
            Repository: ${{ github.repository }}
            Commit: ${{ github.sha }}
            Author: ${{ github.actor }}
            Message: ${{ github.event.head_commit.message }}
            
            Image pushed to ECR: ${{ github.sha }}
            
            View deployment: http://a594e11411ab740019c57084a40b5fa5-1983588965.us-east-1.elb.amazonaws.com
            
      - name: Send failure email
        if: failure()
        uses: dawidd6/action-send-mail@v3
        with:
          server_address: smtp.gmail.com
          server_port: 465
          username: ${{ secrets.EMAIL_USERNAME }}
          password: ${{ secrets.EMAIL_PASSWORD }}
          subject: "❌ Deployment Failed - FilmCastPro"
          to: jamalsadaf3@gmail.com
          from: GitHub Actions
          body: |
            Deployment failed!
            
            Repository: ${{ github.repository }}
            Commit: ${{ github.sha }}
            Author: ${{ github.actor }}
            
            Check logs: https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}
```

**Setup Gmail App Password:**
1. Go to: https://myaccount.google.com/apppasswords
2. Select "Mail" and "Other (Custom name)"
3. Name it "GitHub Actions"
4. Copy the generated password

**Add to GitHub Secrets:**
```
EMAIL_USERNAME: jamalsadaf3@gmail.com
EMAIL_PASSWORD: [your-16-char-app-password]
```

---

## 🔔 Option 2: ArgoCD Email Notifications

### Setup ArgoCD Notifications Controller

#### Step 1: Install ArgoCD Notifications

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-notifications/release-1.0/manifests/install.yaml
```

#### Step 2: Configure Email Settings

Create email configuration:

```bash
kubectl create secret generic argocd-notifications-secret \
  -n argocd \
  --from-literal=email-username=jamalsadaf3@gmail.com \
  --from-literal=email-password='your-app-password'
```

Create ConfigMap for email settings:

```yaml
# argocd/notifications-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.email.gmail: |
    username: $email-username
    password: $email-password
    host: smtp.gmail.com
    port: 465
    from: jamalsadaf3@gmail.com
  
  template.app-deployed: |
    email:
      subject: ✅ Application {{.app.metadata.name}} deployed
    message: |
      Application {{.app.metadata.name}} has been successfully deployed!
      
      Sync Status: {{.app.status.sync.status}}
      Health Status: {{.app.status.health.status}}
      Repository: {{.app.spec.source.repoURL}}
      Revision: {{.app.status.sync.revision}}
      
      View in ArgoCD: http://a551743f3fc024c65a454d33fc456236-1486486352.us-east-1.elb.amazonaws.com/applications/{{.app.metadata.name}}
  
  template.app-sync-failed: |
    email:
      subject: ❌ Application {{.app.metadata.name}} sync failed
    message: |
      Application {{.app.metadata.name}} sync failed!
      
      Sync Status: {{.app.status.sync.status}}
      Health Status: {{.app.status.health.status}}
      
      View details: http://a551743f3fc024c65a454d33fc456236-1486486352.us-east-1.elb.amazonaws.com/applications/{{.app.metadata.name}}
  
  template.app-health-degraded: |
    email:
      subject: ⚠️ Application {{.app.metadata.name}} degraded
    message: |
      Application {{.app.metadata.name}} health is degraded!
      
      Health Status: {{.app.status.health.status}}
      Sync Status: {{.app.status.sync.status}}
      
      Check pods: kubectl get pods -n filmcastpro
  
  trigger.on-deployed: |
    - when: app.status.sync.status == 'Synced' and app.status.health.status == 'Healthy'
      send: [app-deployed]
  
  trigger.on-sync-failed: |
    - when: app.status.sync.status == 'Unknown' or app.status.sync.status == 'OutOfSync'
      send: [app-sync-failed]
  
  trigger.on-health-degraded: |
    - when: app.status.health.status == 'Degraded'
      send: [app-health-degraded]
```

Apply the configuration:

```bash
kubectl apply -f argocd/notifications-cm.yaml
```

#### Step 3: Subscribe to Notifications

Update your application manifest:

```yaml
# argocd/filmcastpro-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: filmcastpro
  namespace: argocd
  annotations:
    notifications.argoproj.io/subscribe.on-deployed.gmail: jamalsadaf3@gmail.com
    notifications.argoproj.io/subscribe.on-sync-failed.gmail: jamalsadaf3@gmail.com
    notifications.argoproj.io/subscribe.on-health-degraded.gmail: jamalsadaf3@gmail.com
spec:
  # ... rest of your config
```

Apply the updated application:

```bash
kubectl apply -f argocd/filmcastpro-app.yaml
```

---

## 🔔 Option 3: Slack Integration (Alternative)

If you prefer Slack over email:

### GitHub Actions → Slack

```yaml
- name: Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Deployment to EKS completed!'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

### ArgoCD → Slack

```yaml
service.slack: |
  token: $slack-token
template.app-deployed: |
  message: |
    :white_check_mark: Application {{.app.metadata.name}} deployed!
  slack:
    attachments: |
      [{
        "title": "{{ .app.metadata.name}}",
        "color": "good"
      }]
```

---

## 📱 Option 4: Simple Webhook Notifications

### Send to any webhook endpoint

GitHub Actions:

```yaml
- name: Send webhook notification
  run: |
    curl -X POST https://your-webhook-url.com/notify \
      -H "Content-Type: application/json" \
      -d '{
        "status": "success",
        "repo": "${{ github.repository }}",
        "commit": "${{ github.sha }}",
        "message": "${{ github.event.head_commit.message }}"
      }'
```

---

## 🎯 Recommended Setup (Quick Start)

For your setup, I recommend:

### 1. Enable GitHub Email Notifications (1 minute)

```bash
# Just enable in GitHub settings
https://github.com/settings/notifications
→ Check "Actions" under Email
```

### 2. Add Custom Email Action (5 minutes)

Update `.github/workflows/deploy.yml` with email steps (shown above)

Add secrets:
```
EMAIL_USERNAME: jamalsadaf3@gmail.com
EMAIL_PASSWORD: [Gmail app password]
```

### 3. Test It

```bash
# Make a change
echo "// Test notification" >> src/App.tsx
git add src/App.tsx
git commit -m "test: email notification"
git push origin main

# Check your email in ~2 minutes!
```

---

## 📧 Email Notification Examples

### Success Email Example:

```
Subject: ✅ Deployment Success - FilmCastPro

Deployment completed successfully!

Repository: sadaf-jamal-au27/FilmCastPro
Commit: fbd55171234...
Author: sadaf-jamal-au27
Message: feat: update banner with animation

Image pushed to ECR: fbd55171234...

View deployment: http://a594e11411ab740019c57084a40b5fa5...

Time: 2m 34s
Status: Success ✅
```

### Failure Email Example:

```
Subject: ❌ Deployment Failed - FilmCastPro

Deployment failed!

Repository: sadaf-jamal-au27/FilmCastPro
Commit: abc12345...
Author: sadaf-jamal-au27

Error: Failed to push Docker image to ECR

Check logs: https://github.com/sadaf-jamal-au27/FilmCastPro/actions/runs/12345

Status: Failed ❌
```

---

## 🔧 Testing Notifications

### Test GitHub Actions Email:

```bash
# Trigger a workflow
echo "// Test" >> src/App.tsx
git add src/App.tsx
git commit -m "test: email notification"
git push origin main
```

### Test ArgoCD Email:

```bash
# Force a sync
kubectl patch application filmcastpro -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"true"}}}'

# Or manually sync
argocd app sync filmcastpro
```

---

## 📊 Notification Flow Diagram

```
Code Push
    ↓
GitHub Actions Starts
    ↓
Email: "Build Started" 📧
    ↓
Docker Build
    ↓
Push to ECR
    ↓
Email: "Build Success" ✅
    ↓
Update Git
    ↓
ArgoCD Detects Change
    ↓
Email: "Sync Started" 📧
    ↓
Deploy to EKS
    ↓
Email: "Deployment Success" ✅
    ↓
Email: "App Healthy" 💚
```

---

## 🐛 Troubleshooting

### Gmail App Password Not Working

**Issue:** "Invalid credentials" error

**Solution:**
1. Enable 2-Factor Authentication on Gmail
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use the 16-character password (no spaces)

### Not Receiving Emails

**Check:**
```bash
# Check GitHub Actions logs
https://github.com/sadaf-jamal-au27/FilmCastPro/actions

# Check spam folder
# Add GitHub to safe senders

# Verify secret is set
https://github.com/sadaf-jamal-au27/FilmCastPro/settings/secrets/actions
```

### ArgoCD Notifications Not Working

**Check:**
```bash
# Check notifications controller
kubectl get pods -n argocd | grep notifications

# Check logs
kubectl logs -n argocd deployment/argocd-notifications-controller

# Verify secret
kubectl get secret argocd-notifications-secret -n argocd
```

---

## 🎓 Best Practices

1. **Use different emails for different environments**
   - Dev: dev-team@company.com
   - Prod: ops-team@company.com

2. **Set up email filters**
   - Auto-label deployment emails
   - Keep inbox clean

3. **Include important details**
   - Commit hash
   - Author
   - Deploy time
   - Direct links

4. **Use emoji for quick scanning**
   - ✅ Success
   - ❌ Failure
   - ⚠️ Warning
   - 📦 Build
   - 🚀 Deploy

5. **Don't spam**
   - Only notify on important events
   - Combine multiple notifications
   - Use digest emails for minor changes

---

## 📚 Additional Resources

- **GitHub Actions Email:** https://github.com/dawidd6/action-send-mail
- **ArgoCD Notifications:** https://argocd-notifications.readthedocs.io/
- **Gmail App Passwords:** https://support.google.com/accounts/answer/185833

---

## 🎯 Quick Implementation Script

Save this as `setup-notifications.sh`:

```bash
#!/bin/bash

echo "Setting up email notifications..."

# Install ArgoCD notifications
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-notifications/release-1.0/manifests/install.yaml

# Create email secret
read -p "Enter your Gmail address: " EMAIL
read -sp "Enter Gmail app password: " PASSWORD
echo ""

kubectl create secret generic argocd-notifications-secret \
  -n argocd \
  --from-literal=email-username=$EMAIL \
  --from-literal=email-password=$PASSWORD \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Notifications configured!"
echo "Now update your application with notification annotations."
```

---

**Last Updated:** October 6, 2025  
**Version:** 1.0  
**Your Email:** jamalsadaf3@gmail.com

