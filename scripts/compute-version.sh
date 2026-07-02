#!/usr/bin/env bash
set -euo pipefail

# Computes publish version from package.json base version.
# Usage:
#   compute-version.sh pr <pr_number> <run_number>
#   compute-version.sh staging <run_number>
#   compute-version.sh stable

CHANNEL="${1:?channel required: pr|staging|stable}"
BASE="$(jq -r '.version' package.json)"

case "${CHANNEL}" in
  pr)
    PR_NUMBER="${2:?PR number required}"
    RUN_NUMBER="${3:?run number required}"
    echo "${BASE}-pr.${PR_NUMBER}.${RUN_NUMBER}"
    ;;
  staging)
    RUN_NUMBER="${2:?run number required}"
    echo "${BASE}-staging.${RUN_NUMBER}"
    ;;
  stable)
    echo "${BASE}"
    ;;
  *)
    echo "Unknown channel: ${CHANNEL}" >&2
    exit 1
    ;;
esac
