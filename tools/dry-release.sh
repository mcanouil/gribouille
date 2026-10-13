#!/usr/bin/env bash
# Local dry-run of the Typst Universe release pipeline.
# Stages the same payload as `tools/package.sh stage` (the submitter in
# .github/scripts/publish-typst-universe.sh), installs it locally as
# @preview/gribouille:<version> via a symlink under Typst's data dir, compiles
# every example and the star history chart against it, then removes the
# symlink. No git tag, no GitHub Release, no upstream PR.

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

# The examples import @preview/gribouille as a reader does, so each one compiles
# against the staged payload above, not the working tree. A file the payload
# leaves out fails here rather than for the first user.
compiled=0
failed=()
for f in examples/*.typ .github/star-history/star-history.typ; do
  if typst compile --root "${REPO_ROOT}" "${f}" "${STAGE_ROOT}/$(basename "${f%.typ}").pdf"; then
    compiled=$((compiled + 1))
  else
    failed+=("${f}")
  fi
done
if [[ ${#failed[@]} -gt 0 ]]; then
  printf '\n%d file(s) failed against the staged payload at %s:\n' "${#failed[@]}" "${STAGE}" >&2
  printf '  %s\n' "${failed[@]}" >&2
  printf 'Check that tools/package.sh stage copies every file these need.\n' >&2
  exit 1
fi
printf 'Compiled %d file(s) against the staged payload\n' "${compiled}"

if command -v typst-package-check >/dev/null 2>&1; then
  typst-package-check check "${STAGE}"
else
  printf 'typst-package-check not installed; skipping manifest lint.\n'
fi

printf '\nDry-run OK for gribouille:%s\n' "${VERSION}"
