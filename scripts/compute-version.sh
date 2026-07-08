#!/usr/bin/env bash
set -euo pipefail

# Computes publish version strings from the latest git tag (source of truth on main).
#
# Usage:
#   compute-version.sh latest
#   compute-version.sh bump <patch|minor|major>
#   compute-version.sh pr <impact> <pr_number> <run_number>
#   compute-version.sh testing <run_number>
#   compute-version.sh stable <impact>

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/version-lib.sh
source "${ROOT}/scripts/version-lib.sh"

COMMAND="${1:?command required}"

case "${COMMAND}" in
  latest)
    get_latest_version
    ;;
  bump)
    IMPACT="${2:?impact required}"
    CURRENT="$(get_latest_version)"
    bump_semver "${CURRENT}" "${IMPACT}"
    ;;
  pr)
    IMPACT="${2:?impact required}"
    PR_NUMBER="${3:?PR number required}"
    RUN_NUMBER="${4:?run number required}"
    BASE="$(get_latest_version)"
    NEXT="$(bump_semver "${BASE}" "${IMPACT}")"
    echo "${NEXT}-pr.${PR_NUMBER}.${RUN_NUMBER}"
    ;;
  testing)
    RUN_NUMBER="${2:?run number required}"
    BASE="$(get_latest_version)"
    echo "${BASE}-testing.${RUN_NUMBER}"
    ;;
  stable)
    IMPACT="${2:?impact required}"
    BASE="$(get_latest_version)"
    bump_semver "${BASE}" "${IMPACT}"
    ;;
  *)
    echo "Unknown command: ${COMMAND}" >&2
    echo "Usage: compute-version.sh latest|bump|pr|testing|stable" >&2
    exit 1
    ;;
esac
