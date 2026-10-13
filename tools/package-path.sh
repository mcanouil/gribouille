#!/usr/bin/env bash
# Links a Typst package directory back to this repository, so a document that
# imports @preview/gribouille:<version> compiles against the working tree. The
# version comes from typst.toml, so a bump needs no edit here.
#
# Used by tools/check.sh for the examples and by docs/_scripts/package-path.sh
# for the documentation, whose gallery shows those examples as a user writes them.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

manifest_version() {
  awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' "$1"
}

link_package() {
  local dir="$1" version="$2"
  if [[ -z "${version}" ]]; then
    printf 'package-path: typst.toml names no version; got an empty string. Set version = "x.y.z" in typst.toml.\n' >&2
    return 1
  fi
  mkdir -p "${dir}/preview/gribouille"
  ln -sfn "${REPO_ROOT}" "${dir}/preview/gribouille/${version}"
  printf '%s\n' "${dir}"
}

if [[ "${1:-}" == "--self-test" ]]; then
  probe="$(mktemp -d)"
  trap 'rm -rf "${probe}"' EXIT
  bad=0
  printf 'version = "9.8.7"\n' >"${probe}/typst.toml"
  if [[ "$(manifest_version "${probe}/typst.toml")" != "9.8.7" ]]; then
    bad=$((bad + 1))
    printf '  FAIL  self-test  reads the manifest version\n' >&2
  fi
  link_package "${probe}/packages" "9.8.7" >/dev/null || true
  if [[ "$(readlink "${probe}/packages/preview/gribouille/9.8.7" 2>/dev/null)" != "${REPO_ROOT}" ]]; then
    bad=$((bad + 1))
    printf '  FAIL  self-test  links the version to the repository\n' >&2
  fi
  if link_package "${probe}/empty" "" 2>/dev/null; then
    bad=$((bad + 1))
    printf '  FAIL  self-test  refuses an empty version\n' >&2
  fi
  if [[ ${bad} -gt 0 ]]; then
    printf 'package-path: %d/3 self-test case(s) failed\n' "${bad}" >&2
    exit 1
  fi
  printf 'package:  path self-test 3/3\n'
  exit 0
fi

if [[ $# -ne 1 ]]; then
  printf 'package-path: expected one directory; got %s argument(s). Run tools/package-path.sh <dir>.\n' "$#" >&2
  exit 2
fi

link_package "$1" "$(manifest_version "${REPO_ROOT}/typst.toml")"
