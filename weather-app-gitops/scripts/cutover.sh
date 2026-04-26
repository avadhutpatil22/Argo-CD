#!/usr/bin/env bash
# cutover.sh — Switch live traffic between blue and green slots
# Usage: ./scripts/cutover.sh <blue|green>
set -euo pipefail

NAMESPACE="weather-app"
ACTIVE_SVC="weather-app-active"
PREVIEW_SVC="weather-app-preview"
TARGET="${1:-}"

if [[ "$TARGET" != "blue" && "$TARGET" != "green" ]]; then
  echo "Usage: $0 <blue|green>"; exit 1
fi

INACTIVE="green"; [[ "$TARGET" == "green" ]] && INACTIVE="blue"

echo "▶  Active  → ${TARGET}"
echo "▶  Preview → ${INACTIVE}"

kubectl patch service "$ACTIVE_SVC" -n "$NAMESPACE" --type=merge \
  -p "{\"spec\":{\"selector\":{\"slot\":\"${TARGET}\"}},\"metadata\":{\"annotations\":{\"deployment.blue-green/active-slot\":\"${TARGET}\"}}}"

kubectl patch service "$PREVIEW_SVC" -n "$NAMESPACE" --type=merge \
  -p "{\"spec\":{\"selector\":{\"slot\":\"${INACTIVE}\"}},\"metadata\":{\"annotations\":{\"deployment.blue-green/preview-slot\":\"${INACTIVE}\"}}}"

echo "✅  Cutover to ${TARGET} complete."
