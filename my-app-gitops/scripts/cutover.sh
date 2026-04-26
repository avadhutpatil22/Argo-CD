#!/usr/bin/env bash
##############################################################
# cutover.sh — Toggle active traffic between blue and green
#
# Usage:
#   ./cutover.sh blue    # point active service at blue slot
#   ./cutover.sh green   # point active service at green slot
#
# Prerequisites: kubectl configured, namespace "my-app" exists
##############################################################

set -euo pipefail

NAMESPACE="my-app"
ACTIVE_SVC="my-app-active"
PREVIEW_SVC="my-app-preview"

TARGET="${1:-}"

if [[ "$TARGET" != "blue" && "$TARGET" != "green" ]]; then
  echo "Usage: $0 <blue|green>"
  exit 1
fi

INACTIVE="green"
[[ "$TARGET" == "green" ]] && INACTIVE="blue"

echo "▶  Switching ACTIVE  → ${TARGET}"
echo "▶  Switching PREVIEW → ${INACTIVE}"

# Patch active service
kubectl patch service "$ACTIVE_SVC" \
  -n "$NAMESPACE" \
  --type=merge \
  -p "{\"spec\":{\"selector\":{\"slot\":\"${TARGET}\"}},\"metadata\":{\"annotations\":{\"deployment.blue-green/active-slot\":\"${TARGET}\"}}}"

# Patch preview service
kubectl patch service "$PREVIEW_SVC" \
  -n "$NAMESPACE" \
  --type=merge \
  -p "{\"spec\":{\"selector\":{\"slot\":\"${INACTIVE}\"}},\"metadata\":{\"annotations\":{\"deployment.blue-green/preview-slot\":\"${INACTIVE}\"}}}"

echo ""
echo "✅  Cutover complete."
echo "    Active  → ${TARGET}   (${ACTIVE_SVC})"
echo "    Preview → ${INACTIVE} (${PREVIEW_SVC})"
echo ""
echo "Verify with:"
echo "  kubectl get svc -n ${NAMESPACE} -o wide"
echo "  kubectl get pods -n ${NAMESPACE} -l app=my-app --show-labels"
