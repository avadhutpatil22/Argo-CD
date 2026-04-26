#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# build-push.sh
# Builds and pushes blue AND green Docker images to GHCR.
#
# Usage:
#   ./scripts/build-push.sh                  # builds both slots
#   ./scripts/build-push.sh blue             # builds only blue
#   ./scripts/build-push.sh green            # builds only green
#
# Prerequisites:
#   - Docker installed and running
#   - Logged in to GHCR:
#       echo "YOUR_TOKEN" | docker login ghcr.io -u avadhutpatil22 --password-stdin
# ─────────────────────────────────────────────────────────────
set -euo pipefail

# ── Config ────────────────────────────────────────────────────
REGISTRY="ghcr.io"
IMAGE_NAME="avadhutpatil22/weather-app"
BLUE_VERSION="1.0.0"
GREEN_VERSION="1.1.0"
TARGET="${1:-both}"   # blue | green | both

IMAGE_BASE="${REGISTRY}/${IMAGE_NAME}"

# ── Colours ───────────────────────────────────────────────────
BLUE='\033[0;34m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'
BOLD='\033[1m'

log()  { echo -e "${CYAN}▶  $1${RESET}"; }
ok()   { echo -e "${GREEN}✅  $1${RESET}"; }
info() { echo -e "${BOLD}$1${RESET}"; }

# ── Check Docker is running ───────────────────────────────────
if ! docker info > /dev/null 2>&1; then
  echo "❌  Docker is not running. Please start Docker first."
  exit 1
fi

# ── Move to repo root ─────────────────────────────────────────
cd "$(dirname "$0")/.."

# ── Build function ────────────────────────────────────────────
build_and_push() {
  local SLOT=$1
  local VERSION=$2

  info "\n════════════════════════════════════════"
  info "  Building SLOT=${SLOT}  VERSION=${VERSION}"
  info "════════════════════════════════════════"

  log "Building image..."
  docker build \
    --build-arg SLOT="${SLOT}" \
    --build-arg VERSION="${VERSION}" \
    --tag "${IMAGE_BASE}:${SLOT}" \
    --tag "${IMAGE_BASE}:${SLOT}-${VERSION}" \
    --tag "${IMAGE_BASE}:${VERSION}-${SLOT}" \
    --platform linux/amd64 \
    .

  ok "Build complete → ${IMAGE_BASE}:${SLOT}"

  log "Pushing tags to GHCR..."
  docker push "${IMAGE_BASE}:${SLOT}"
  docker push "${IMAGE_BASE}:${SLOT}-${VERSION}"
  docker push "${IMAGE_BASE}:${VERSION}-${SLOT}"

  ok "Pushed → ${IMAGE_BASE}:${SLOT}"
  ok "Pushed → ${IMAGE_BASE}:${SLOT}-${VERSION}"
}

# ── Also tag blue as :latest ──────────────────────────────────
tag_latest() {
  log "Tagging blue as :latest..."
  docker tag "${IMAGE_BASE}:blue" "${IMAGE_BASE}:latest"
  docker push "${IMAGE_BASE}:latest"
  ok "Pushed → ${IMAGE_BASE}:latest"
}

# ── Run ───────────────────────────────────────────────────────
case "$TARGET" in
  blue)
    build_and_push "blue"  "$BLUE_VERSION"
    tag_latest
    ;;
  green)
    build_and_push "green" "$GREEN_VERSION"
    ;;
  both)
    build_and_push "blue"  "$BLUE_VERSION"
    tag_latest
    build_and_push "green" "$GREEN_VERSION"
    ;;
  *)
    echo "Usage: $0 [blue|green|both]"
    exit 1
    ;;
esac

# ── Summary ───────────────────────────────────────────────────
echo ""
info "════════════════════════════════════════"
info "  Images pushed to GHCR:"
info "════════════════════════════════════════"
echo ""
echo -e "  ${BLUE}BLUE  slot:${RESET}"
echo "    ghcr.io/avadhutpatil22/weather-app:blue"
echo "    ghcr.io/avadhutpatil22/weather-app:blue-${BLUE_VERSION}"
echo "    ghcr.io/avadhutpatil22/weather-app:latest"
echo ""
echo -e "  ${GREEN}GREEN slot:${RESET}"
echo "    ghcr.io/avadhutpatil22/weather-app:green"
echo "    ghcr.io/avadhutpatil22/weather-app:green-${GREEN_VERSION}"
echo ""
info "════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Make package public → https://github.com/avadhutpatil22?tab=packages"
echo "  2. Sync Argo CD:"
echo "       argocd app sync weather-app-blue"
echo "       argocd app sync weather-app-green"
echo ""
