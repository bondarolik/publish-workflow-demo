#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# CODEARTIFACT PUBLISH — DevOps implements this script for cm_protos production.
# =============================================================================
#
# Replace the dry-run call to ./scripts/publish.sh in these workflows:
#   - .github/workflows/publish-pr.yml
#   - .github/workflows/publish-testing.yml
#   - .github/workflows/publish-main.yml
#
# Required environment (set by caller):
#   VERSION      — semver string to publish (e.g. 1.3.0-pr.4.2, 1.2.0-testing.5, 1.3.0)
#   DIST_TAG     — npm dist-tag (pr-N, testing, latest)
#   CHANNEL      — PR | TESTING | STABLE (logging only)
#   PACKAGE_NAME — default @lifestance/protos-demo
#
# Example implementation:
#
#   : "${VERSION:?}"
#   : "${DIST_TAG:?}"
#   PACKAGE_NAME="${PACKAGE_NAME:-@lifestance/protos-demo}"
#
#   aws codeartifact login \
#     --tool npm \
#     --domain "${CA_DOMAIN}" \
#     --domain-owner "${CA_ACCOUNT_ID}" \
#     --repository "${CA_REPOSITORY}"
#
#   npm publish --tag "${DIST_TAG}"
#   # or: pnpm publish --tag "${DIST_TAG}" --no-git-checks
#
# =============================================================================

echo "::warning::publish-codeartifact.sh is a stub — DevOps must implement CodeArtifact publish."
