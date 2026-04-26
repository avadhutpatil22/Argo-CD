# 🌤 Weather App — Blue-Green GitOps

A minimal weather web app deployed via **Argo CD blue-green strategy** on Kubernetes.

---

## Repository Structure

```
weather-app-gitops/
├── .github/
│   └── workflows/
│       └── build.yml              # CI: build & push Docker image
│
├── app/                           # Frontend source
│   ├── index.html
│   ├── style.css
│   └── app.js
│
├── apps/                          # Argo CD CRDs
│   ├── app-project.yaml
│   ├── app-blue.yaml
│   └── app-green.yaml
│
├── manifests/
│   ├── base/                      # Shared K8s resources
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   └── services.yaml          # active + preview services
│   └── overlays/
│       ├── blue/                  # Stable slot
│       │   └── kustomization.yaml
│       └── green/                 # Candidate slot
│           └── kustomization.yaml
│
├── scripts/
│   └── cutover.sh                 # Traffic switch helper
│
├── Dockerfile
├── nginx.conf
└── README.md
```

---

## How It Works

```
  Users  ──►  weather-app-active  ──► Pods (slot=blue)   ← stable
  QA     ──►  weather-app-preview ──► Pods (slot=green)  ← candidate
```

---

## Setup

### 1. Add your OpenWeatherMap API key

Edit `app/app.js`:
```js
const API_KEY = 'your_key_here';
```

Get a free key at https://openweathermap.org/api

### 2. Update image references

Replace `<your-org>` in:
- `manifests/base/deployment.yaml`
- `manifests/overlays/blue/kustomization.yaml`
- `manifests/overlays/green/kustomization.yaml`
- `apps/app-blue.yaml`
- `apps/app-green.yaml`
- `apps/app-project.yaml`

### 3. Build Docker image

```bash
# Blue slot (stable)
docker build --build-arg SLOT=blue --build-arg VERSION=1.0.0 \
  -t ghcr.io/<your-org>/weather-app:1.0.0 .

# Green slot (candidate)
docker build --build-arg SLOT=green --build-arg VERSION=1.1.0 \
  -t ghcr.io/<your-org>/weather-app:1.1.0 .
```

### 4. Apply Argo CD resources

```bash
kubectl apply -f apps/app-project.yaml -n argocd
kubectl apply -f apps/app-blue.yaml    -n argocd
kubectl apply -f apps/app-green.yaml   -n argocd
```

### 5. Test green slot

```bash
kubectl port-forward svc/weather-app-preview 8080:80 -n weather-app
open http://localhost:8080
```

### 6. Cut over to green

```bash
./scripts/cutover.sh green
```

### 7. Rollback

```bash
./scripts/cutover.sh blue
```

---

## CI/CD Flow

```
git push → GitHub Actions builds image
         → pushes to GHCR
         → updates image tag in overlays/green/kustomization.yaml
         → Argo CD detects diff → auto-syncs green Deployment
         → test via preview service
         → run cutover.sh green to go live
```
