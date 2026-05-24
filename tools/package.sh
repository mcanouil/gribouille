#!/usr/bin/env bash
# Canonical package payload assembler, reused by the GitHub Release archives,
# the Typst Universe submission, the package-check job, the local dry-run, and
# the development build deployed to the docs site. Producing the payload in one
# place keeps all of them byte-identical.
#
# Usage:
#   package.sh stage   <dest-dir> [version]
#   package.sh archive <out-dir> [basename] [version]
#
# stage   fills <dest-dir> with the published payload (typst.toml, lib.typ,
#         LICENSE, stripped README, src/ minus GLOSSARY.md). When [version] is
#         given (development build), the staged typst.toml is rewritten to that
#         version and stamped with the source commit.
# archive stages into a temporary dir then writes <out-dir>/<basename>.tar.gz
#         and <out-dir>/<basename>.zip. version defaults to the typst.toml
#         value; basename defaults to gribouille-<version>.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

read_version() {
  awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml
}

stage() {
  local dest="${1:?stage: destination dir required}"
  local version="${2:-}"

  mkdir -p "${dest}"
  cp typst.toml lib.typ LICENSE "${dest}/"
  tools/stage-readme.sh README.md "${dest}"
  cp -r src "${dest}/"
  rm -f "${dest}/src/GLOSSARY.md"

  if [[ -n "${version}" ]]; then
    local commit date_utc
    commit="$(git describe --tags --always)"
    date_utc="$(date -u +%Y-%m-%d)"
    sed -E -i.bak \
      -e "s/^(version[[:space:]]*=[[:space:]]*\")[^\"]+/\1${version}/" \
      "${dest}/typst.toml"
    rm -f "${dest}/typst.toml.bak"
    printf '# dev build: %s (%s)\n%s' \
      "${commit}" "${date_utc}" "$(cat "${dest}/typst.toml")" \
      > "${dest}/typst.toml"
  fi
}

archive() {
  local out_dir="${1:?archive: output dir required}"
  local basename="${2:-}"
  local version="${3:-}"

  [[ -n "${version}" ]] || version="$(read_version)"
  [[ -n "${version}" ]] || { echo "archive: version not found in typst.toml" >&2; exit 1; }
  [[ -n "${basename}" ]] || basename="gribouille-${version}"

  local tmp leaf
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN
  leaf="gribouille-${version}"
  stage "${tmp}/${leaf}" "${3:-}"

  mkdir -p "${out_dir}"
  out_dir="$(cd "${out_dir}" && pwd)"
  rm -f "${out_dir}/${basename}.tar.gz" "${out_dir}/${basename}.zip"
  tar -czf "${out_dir}/${basename}.tar.gz" -C "${tmp}" "${leaf}"
  (cd "${tmp}" && zip -qr "${out_dir}/${basename}.zip" "${leaf}")
}

cmd="${1:-}"
case "${cmd}" in
  stage)   shift; stage "$@" ;;
  archive) shift; archive "$@" ;;
  *)
    echo "usage: package.sh {stage <dest-dir> [version] | archive <out-dir> [basename] [version]}" >&2
    exit 1
    ;;
esac
