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

if ! IMPACT="$(parse_version_impact_from_file "${BODY_FILE}")"; then
  if grep -qE '^## Version Impact[[:space:]]*$' "${BODY_FILE}"; then
    if grep -qE '^- \[[xX]\]' "${BODY_FILE}"; then
      echo "::error::Check exactly one option under ## Version Impact (patch, minor, major, or none)."
    else
      echo "::error::Select a version impact under ## Version Impact — check exactly one box."
    fi
  else
    echo "::error::Version impact is required. Use the PR template and check exactly one box under ## Version Impact."
  fi
  exit 1
fi

echo "Version impact: ${IMPACT}"

case "${IMPACT}" in
  major)
    if ! has_label "${LABELS_CSV}" "version:major-approved"; then
      echo "::error::Major releases require the \`version:major-approved\` label from the git guardian after tech meeting approval."
      exit 1
    fi
    ;;
  none)
    if [[ -z "${BASE_REF}" || -z "${HEAD_REF}" ]]; then
      echo "::error::Internal error: base/head refs required to validate none paths."
      exit 1
    fi

    mapfile -t CHANGED_FILES < <(git diff --name-only "${BASE_REF}...${HEAD_REF}")

    if [[ "${#CHANGED_FILES[@]}" -eq 0 ]]; then
      echo "::error::No changed files detected for none validation."
      exit 1
    fi

    DISALLOWED=()
    for file in "${CHANGED_FILES[@]}"; do
      if ! is_none_allowlisted_path "${file}"; then
        DISALLOWED+=("${file}")
      fi
    done

    if [[ "${#DISALLOWED[@]}" -gt 0 ]]; then
      echo "::error::Version impact 'none' is only allowed for docs, markdown, .github, and similar paths."
      printf '::error::Disallowed path for none: %s\n' "${DISALLOWED[@]}"
      exit 1
    fi
    ;;
esac

echo "version-impact check passed (${IMPACT})."
