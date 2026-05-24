#!/usr/bin/env bash
# Local dry-run of the Typst Universe release pipeline.
# Stages the same payload as release.yml's typst-universe job, installs it
# locally as @preview/gribouille:<version> via a symlink under Typst's data
# dir, compiles a smoke file, then removes the symlink. No git tag, no
# GitHub Release, no upstream PR.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

VERSION="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
[[ -n "${VERSION}" ]] || { echo "version not found in typst.toml" >&2; exit 1; }

STAGE_ROOT="/tmp/gribouille-dry-release"
STAGE="${STAGE_ROOT}/gribouille/${VERSION}"

case "$(uname -s)" in
  Darwin) DATA_DIR="${HOME}/Library/Application Support/typst" ;;
  Linux)  DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/typst" ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
INSTALL_DIR="${DATA_DIR}/packages/preview/gribouille"
INSTALL_LINK="${INSTALL_DIR}/${VERSION}"

cleanup() {
  if [[ -L "${INSTALL_LINK}" ]]; then
    rm -f "${INSTALL_LINK}"
  fi
}
trap cleanup EXIT

rm -rf "${STAGE_ROOT}"
tools/package.sh stage "${STAGE}"
printf 'Staged payload at %s\n' "${STAGE}"

mkdir -p "${INSTALL_DIR}"
if [[ -e "${INSTALL_LINK}" && ! -L "${INSTALL_LINK}" ]]; then
  echo "${INSTALL_LINK} exists and is not a symlink; refusing to overwrite" >&2
  exit 1
fi
ln -sfn "${STAGE}" "${INSTALL_LINK}"
printf 'Linked @preview/gribouille:%s -> %s\n' "${VERSION}" "${STAGE}"

SMOKE="${STAGE_ROOT}/smoke.typ"
cat > "${SMOKE}" <<TYP
#import "@preview/gribouille:${VERSION}": plot, aes, geom-point, penguins

#plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass"),
  layers: (geom-point(),),
  width: 8cm,
  height: 6cm,
)
TYP

typst compile "${SMOKE}" "${STAGE_ROOT}/smoke.pdf"
printf 'Smoke compile OK: %s\n' "${STAGE_ROOT}/smoke.pdf"

if command -v typst-package-check >/dev/null 2>&1; then
  typst-package-check check "${STAGE}"
else
  printf 'typst-package-check not installed; skipping manifest lint.\n'
fi

printf '\nDry-run OK for gribouille:%s\n' "${VERSION}"
