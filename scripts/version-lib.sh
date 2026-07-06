#!/usr/bin/env bash
# Shared semver helpers. Source from other scripts — do not execute directly.

semver_regex='^[0-9]+\.[0-9]+\.[0-9]+$'

get_latest_version() {
  git fetch --tags --force origin 2>/dev/null || true

  local latest
  latest="$(git tag -l | grep -E "${semver_regex}" | sort -V | tail -n 1 || true)"

  if [[ -z "${latest}" ]]; then
    echo "0.0.0"
  else
    echo "${latest}"
  fi
}

bump_semver() {
  local current="${1:?current version required}"
  local impact="${2:?impact required: patch|minor|major}"

  if [[ ! "${current}" =~ ${semver_regex} ]]; then
    echo "Invalid semver: ${current}" >&2
    return 1
  fi

  local major minor patch
  IFS=. read -r major minor patch <<< "${current}"

  case "${impact}" in
    patch) echo "${major}.${minor}.$((patch + 1))" ;;
    minor) echo "${major}.$((minor + 1)).0" ;;
    major) echo "$((major + 1)).0.0" ;;
    *)
      echo "Invalid impact for bump: ${impact}" >&2
      return 1
      ;;
  esac
}

parse_version_impact_from_file() {
  local body_file="${1:?body file required}"

  local impact
  impact="$(awk '
    /^### Version impact[[:space:]]*$/ {
      capture = 1
      next
    }
    capture && (/^### / || /^## /) {
      capture = 0
    }
    capture && /^[[:space:]]*$/ {
      next
    }
    capture {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print $0
      exit
    }
  ' "${body_file}")"

  case "${impact}" in
    patch|minor|major|none) echo "${impact}" ;;
    *)
      echo "invalid"
      return 1
      ;;
  esac
}

is_none_allowlisted_path() {
  local file="${1:?file required}"

  case "${file}" in
    *.md) return 0 ;;
    docs/*) return 0 ;;
    .github/*) return 0 ;;
    README*) return 0 ;;
    .gitignore) return 0 ;;
    LICENSE*) return 0 ;;
    *) return 1 ;;
  esac
}

validate_none_paths() {
  local file

  while IFS= read -r file; do
    [[ -z "${file}" ]] && continue
    if ! is_none_allowlisted_path "${file}"; then
      echo "${file}"
      return 1
    fi
  done

  return 0
}

has_label() {
  local labels_csv="${1:-}"
  local wanted="${2:?label required}"

  local labels
  labels=",${labels_csv},"
  [[ "${labels}" == *",${wanted},"* ]]
}
