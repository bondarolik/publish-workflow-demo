#!/usr/bin/env bash
set -euo pipefail

# Logs what would be published in production (no registry calls).
# Required env: VERSION, DIST_TAG, CHANNEL

: "${VERSION:?VERSION is required}"
: "${DIST_TAG:?DIST_TAG is required}"
: "${CHANNEL:?CHANNEL is required}"

PACKAGE_NAME="${PACKAGE_NAME:-@lifestance/protos-demo}"

BANNER=$(cat <<EOF
╔══════════════════════════════════════════════════════════════╗
║  DRY RUN — no package published                              ║
╠══════════════════════════════════════════════════════════════╣
║  Channel:   ${CHANNEL}
║  Package:   ${PACKAGE_NAME}
║  Version:   ${VERSION}
║  Dist-tag:  ${DIST_TAG}
║  Install:   pnpm add ${PACKAGE_NAME}@${DIST_TAG}
║  Exact pin: pnpm add ${PACKAGE_NAME}@${VERSION}
╚══════════════════════════════════════════════════════════════╝
EOF
)

echo "${BANNER}"
echo "::notice title=DRY RUN ${CHANNEL}::Would publish ${PACKAGE_NAME}@${VERSION} (tag: ${DIST_TAG})"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### DRY RUN — ${CHANNEL}"
    echo ""
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| Package | \`${PACKAGE_NAME}\` |"
    echo "| Version | \`${VERSION}\` |"
    echo "| Dist-tag | \`${DIST_TAG}\` |"
    echo "| Would install | \`pnpm add ${PACKAGE_NAME}@${DIST_TAG}\` |"
  } >> "${GITHUB_STEP_SUMMARY}"
fi
