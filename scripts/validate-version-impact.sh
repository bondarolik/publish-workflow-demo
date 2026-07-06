#!/usr/bin/env bash
set -euo pipefail

# Validates PR version impact declaration and path rules for "none".
#
# Usage:
#   validate-version-impact.sh \
#     --body /tmp/pr-body.md \
#     --labels "ready-for-qa,version:major-approved" \
#     --base-ref origin/main \
#     --head-ref HEAD

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/version-lib.sh
source "${ROOT}/scripts/version-lib.sh"

BODY_FILE=""
LABELS_CSV=""
BASE_REF=""
HEAD_REF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --body)
      BODY_FILE="$2"
      shift 2
      ;;
    --labels)
      LABELS_CSV="$2"
      shift 2
      ;;
    --base-ref)
      BASE_REF="$2"
      shift 2
      ;;
    --head-ref)
      HEAD_REF="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${BODY_FILE}" || ! -f "${BODY_FILE}" ]]; then
  echo "::error::PR body file is missing."
  exit 1
fi

fail_with() {
  local reason="$1"
  local message="$2"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "VERSION_IMPACT_FAILURE_REASON=${reason}" >> "${GITHUB_ENV}"
  fi
  echo "::error::${message}"
  exit 1
}

if ! IMPACT="$(parse_version_impact_from_file "${BODY_FILE}")"; then
  if grep -qE '^## Version Impact[[:space:]]*$' "${BODY_FILE}"; then
    if grep -qE '^- \[[xX]\]' "${BODY_FILE}"; then
      fail_with "multiple_selection" "Check exactly one option under ## Version Impact (patch, minor, major, or none)."
    else
      fail_with "missing_selection" "Select a version impact under ## Version Impact — check exactly one box."
    fi
  else
    fail_with "missing_selection" "Version impact is required. Use the PR template and check exactly one box under ## Version Impact."
  fi
fi

echo "Version impact: ${IMPACT}"

case "${IMPACT}" in
  major)
    if ! has_label "${LABELS_CSV}" "version:major-approved"; then
      fail_with "major_pending_approval" "Major releases require the \`version:major-approved\` label from the git guardian after tech meeting approval."
    fi
    ;;
  none)
    if [[ -z "${BASE_REF}" || -z "${HEAD_REF}" ]]; then
      fail_with "internal_error" "Internal error: base/head refs required to validate none paths."
    fi

    mapfile -t CHANGED_FILES < <(git diff --name-only "${BASE_REF}...${HEAD_REF}")

    if [[ "${#CHANGED_FILES[@]}" -eq 0 ]]; then
      fail_with "internal_error" "No changed files detected for none validation."
    fi

    DISALLOWED=()
    for file in "${CHANGED_FILES[@]}"; do
      if ! is_none_allowlisted_path "${file}"; then
        DISALLOWED+=("${file}")
      fi
    done

    if [[ "${#DISALLOWED[@]}" -gt 0 ]]; then
      if [[ -n "${GITHUB_ENV:-}" ]]; then
        printf 'VERSION_IMPACT_DISALLOWED_PATHS=%s\n' "${DISALLOWED[*]}" >> "${GITHUB_ENV}"
      fi
      fail_with "none_disallowed_paths" "Version impact 'none' is only allowed for docs, markdown, .github, and similar paths."
    fi
    ;;
esac

echo "version-impact check passed (${IMPACT})."
