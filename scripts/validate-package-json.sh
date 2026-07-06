#!/usr/bin/env bash
set -euo pipefail

# package.json must be strict JSON (no // comments). Node.js reads it for all github-script steps.
PACKAGE_JSON="${1:-package.json}"

if [[ ! -f "${PACKAGE_JSON}" ]]; then
  echo "::error::${PACKAGE_JSON} not found."
  exit 1
fi

if ! jq empty "${PACKAGE_JSON}" 2>/dev/null; then
  echo "::error::${PACKAGE_JSON} is not valid JSON."
  echo "::error::Do not add comments or edit the version manually — it is synced automatically after stable releases."
  exit 1
fi

VERSION="$(jq -r '.version // empty' "${PACKAGE_JSON}")"
if [[ -z "${VERSION}" ]]; then
  echo "::error::${PACKAGE_JSON} is missing a string \"version\" field."
  exit 1
fi

echo "package.json is valid (version: ${VERSION})."
