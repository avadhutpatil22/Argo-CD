# Blue-Green Deployment with Argo CD

A production-ready blue-green deployment setup using **Argo CD** + **Kustomize**.

---

## Directory Structure

```
argocd-blue-green/
├── base/                         # Shared Kubernetes manifests
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── active-service.yaml       # Routes LIVE traffic
│   ├── preview-service.yaml      # Routes TEST traffic
│   └── kustomization.yaml
├── overlays/
│   ├── blue/                     # Blue slot — stable/current release
│   │   └── kustomization.yaml
│   └── green/                    # Green slot — candidate/new release
│       └── kustomization.yaml
├── argocd/
│   ├── app-project.yaml          # Argo CD AppProject
│   ├── app-blue.yaml             # Argo CD Application (blue)
│   └── app-green.yaml            # Argo CD Application (green)
└── cutover.sh                    # Traffic cutover helper script
```

---

## How It Works

```
          ┌──────────────────────────────────────────────────┐
          │                   Kubernetes                      │
          │                                                   │
  Users ──►  active-service  ──► [slot=blue]  Deployment     │
          │                                                   │
  Tests ──►  preview-service ──► [slot=green] Deployment     │
          │                                                   │
          └──────────────────────────────────────────────────┘
```

| Service            | Selector     | Purpose               |
| ------------------ | ------------ | --------------------- |
| `my-app-active`    | `slot: blue` | Live production traffic |
| `my-app-preview`   | `slot: green`| Pre-release testing   |

---

## Quick Start

### 1. Update the repo URL

Edit `argocd/app-blue.yaml` and `argocd/app-green.yaml`:
```yaml
repoURL: https://github.com/<your-org>/<your-repo>.git
```

### 2. Apply Argo CD resources

```bash
kubectl apply -f argocd/app-project.yaml -n argocd
kubectl apply -f argocd/app-blue.yaml    -n argocd
kubectl apply -f argocd/app-green.yaml   -n argocd
```

### 3. Deploy a new release to green

Update the image tag in `overlays/green/kustomization.yaml`:
```yaml
images:
  - name: nginx
    newTag: "1.27.1"   # ← new version
```

Commit & push. Argo CD auto-syncs the green Deployment.

### 4. Test the preview

```bash
kubectl port-forward svc/my-app-preview 8080:80 -n my-app
curl http://localhost:8080
```

### 5. Cutover to green

```bash
chmod +x cutover.sh
./cutover.sh green
```

Live traffic now flows to the green slot. Blue becomes the preview/fallback.

### 6. Rollback (if needed)

```bash
./cutover.sh blue
```

---

## Automated Image Updates

Both Argo CD Applications are annotated for **Argo CD Image Updater**:

```yaml
argocd-image-updater.argoproj.io/image-list: nginx=nginx
argocd-image-updater.argoproj.io/nginx.update-strategy: semver
argocd-image-updater.argoproj.io/nginx.allow-tags: "~1.27"
```

Install Image Updater:
```bash
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
```

---

## Ingress Integration (optional)

Point your Ingress at `my-app-active` for production traffic and optionally expose `my-app-preview` on a separate hostname for QA:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: my-app
spec:
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-active   # always live slot
                port:
                  number: 80
    - host: preview.myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-preview  # always staging slot
                port:
                  number: 80
```
