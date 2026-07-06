#!/usr/bin/env bash
set -euo pipefail

# Parse version impact from a GitHub PR body (issue form dropdown).
# Usage: parse-version-impact.sh <path-to-pr-body.md>

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/version-lib.sh
source "${ROOT}/scripts/version-lib.sh"

BODY_FILE="${1:?PR body file required}"

parse_version_impact_from_file "${BODY_FILE}"
