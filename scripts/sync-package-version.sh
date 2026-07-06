#!/usr/bin/env bash
set -euo pipefail

# Sync package.json "version" to the released semver.
# Usage: sync-package-version.sh <version>

VERSION="${1:?version required}"
PACKAGE_JSON="${PACKAGE_JSON:-package.json}"

if [[ ! -f "${PACKAGE_JSON}" ]]; then
  echo "package.json not found" >&2
  exit 1
fi

CURRENT="$(jq -r '.version' "${PACKAGE_JSON}")"

if [[ "${CURRENT}" == "${VERSION}" ]]; then
  echo "package.json already at ${VERSION}"
  exit 0
fi

TMP="$(mktemp)"
jq --arg version "${VERSION}" '.version = $version' "${PACKAGE_JSON}" > "${TMP}"
mv "${TMP}" "${PACKAGE_JSON}"
echo "Updated package.json: ${CURRENT} → ${VERSION}"
