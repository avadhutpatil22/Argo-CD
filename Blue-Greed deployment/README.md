# my-app-gitops

> GitOps repository for **my-app** — Blue-Green deployments managed by [Argo CD](https://argo-cd.readthedocs.io/) + [Kustomize](https://kustomize.io/).

---

## Repository Structure

```
my-app-gitops/
├── .gitignore
├── README.md
│
├── apps/                                 # Argo CD CRDs
│   ├── app-project.yaml                  # AppProject (RBAC scoping)
│   ├── app-blue.yaml                     # Application — blue slot (stable)
│   └── app-green.yaml                    # Application — green slot (candidate)
│
├── manifests/                            # Kubernetes manifests
│   ├── base/                             # Shared resources
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── active-service.yaml           # Routes LIVE traffic
│   │   └── preview-service.yaml          # Routes TEST/preview traffic
│   │
│   └── overlays/
│       ├── blue/                         # Blue slot patches + image pin
│       │   └── kustomization.yaml
│       └── green/                        # Green slot patches + image pin
│           └── kustomization.yaml
│
└── scripts/
    └── cutover.sh                        # Traffic cutover helper
```

---

## How Blue-Green Works

```
          ┌───────────────────────────────────────────┐
          │              Kubernetes Cluster            │
          │                                            │
  Users ──►  my-app-active  ──► Pods (slot=blue)      │
          │                                            │
  Tests ──►  my-app-preview ──► Pods (slot=green)     │
          │                                            │
          └───────────────────────────────────────────┘
```

| Service            | Selector      | Purpose                    |
|--------------------|---------------|----------------------------|
| `my-app-active`    | `slot: blue`  | Live production traffic     |
| `my-app-preview`   | `slot: green` | Pre-release / QA testing    |

---

## Getting Started

### Prerequisites
- A running Kubernetes cluster
- Argo CD installed (`kubectl create namespace argocd && kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`)

### 1. Fork / clone this repo and update the `repoURL`

In `apps/app-blue.yaml` and `apps/app-green.yaml`:
```yaml
source:
  repoURL: https://github.com/<your-org>/my-app-gitops.git
```

### 2. Apply Argo CD resources

```bash
kubectl apply -f apps/app-project.yaml -n argocd
kubectl apply -f apps/app-blue.yaml    -n argocd
kubectl apply -f apps/app-green.yaml   -n argocd
```

### 3. Deploy a new release to the green slot

Edit `manifests/overlays/green/kustomization.yaml`:
```yaml
images:
  - name: nginx
    newTag: "1.27.1"   # ← bump to new version
```

Commit and push — Argo CD auto-syncs.

### 4. Test via the preview service

```bash
kubectl port-forward svc/my-app-preview 8080:80 -n my-app
curl http://localhost:8080
```

### 5. Cut over live traffic to green

```bash
chmod +x scripts/cutover.sh
./scripts/cutover.sh green
```

### 6. Rollback instantly

```bash
./scripts/cutover.sh blue
```

---

## Branch Strategy

| Branch   | Purpose                                      |
|----------|----------------------------------------------|
| `main`   | Production — Argo CD syncs from here         |
| `staging`| Pre-production testing before merging to main|
| `feat/*` | Feature branches for manifest changes        |

---

## Secrets

**Never commit secrets.** Use one of:
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [Argo CD Vault Plugin](https://argocd-vault-plugin.readthedocs.io/)
- [External Secrets Operator](https://external-secrets.io/)
