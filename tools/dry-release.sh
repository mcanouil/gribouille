#!/usr/bin/env bash
# Local dry-run of the Typst Universe release pipeline.
# Stages the same payload as `tools/package.sh stage` (the archive that the
# Release workflow submits to Typst Universe), installs it locally as
# @preview/gribouille:<version> via a symlink under Typst's data dir, compiles
# every example and the star history chart against it, lints the payload with
# typst-package-check, then removes the symlink. It refuses a payload that holds
# a dotfile. No git tag, no GitHub Release, no upstream PR.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

VERSION="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
[[ -n "${VERSION}" ]] || {
  echo "version not found in typst.toml" >&2
  exit 1
}

# Checked before any work, so a missing linter fails in seconds rather than
# after the compiles.
if ! command -v typst-package-check >/dev/null 2>&1; then
  printf 'manifest: typst-package-check is not installed\n' >&2
  printf '  install it with: cargo install --git https://github.com/typst/package-check --locked\n' >&2
  exit 1
fi

STAGE_ROOT="${STAGE_ROOT:-/tmp/gribouille-dry-release}"
STAGE="${STAGE_ROOT}/gribouille/${VERSION}"

case "$(uname -s)" in
Darwin) DATA_DIR="${HOME}/Library/Application Support/typst" ;;
Linux) DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/typst" ;;
*)
  echo "unsupported OS: $(uname -s)" >&2
  exit 1
  ;;
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

dotfiles="$(find "${STAGE}" -mindepth 1 -name '.*')"
if [[ -n "${dotfiles}" ]]; then
  printf 'payload: the staged package holds dotfiles\n%s\n' "${dotfiles}" >&2
  exit 1
fi

mkdir -p "${INSTALL_DIR}"
if [[ -e "${INSTALL_LINK}" && ! -L "${INSTALL_LINK}" ]]; then
  echo "${INSTALL_LINK} exists and is not a symlink; refusing to overwrite" >&2
  exit 1
fi
ln -sfn "${STAGE}" "${INSTALL_LINK}"
printf 'Linked @preview/gribouille:%s -> %s\n' "${VERSION}" "${STAGE}"

# The examples import the working tree with `#import "/lib.typ"`. A copy of each
# one gets the import a reader types instead, as the documentation shows it, and
# compiles against the staged payload above. The copies sit in their own root,
# with no lib.typ, so nothing can resolve to the working tree. A file the payload
# leaves out fails here rather than for the first user.
SHOWN="${STAGE_ROOT}/shown"
mkdir -p "${SHOWN}/.github" "${SHOWN}/docs/assets"
cp -R examples "${SHOWN}/"
cp -R .github/star-history "${SHOWN}/.github/"
cp -R docs/assets/images "${SHOWN}/docs/assets/"
compiled=0
failed=()
for f in examples/*.typ .github/star-history/star-history.typ; do
  sed 's|^#import "/lib.typ": \*$|#import "@preview/gribouille:'"${VERSION}"'": *|' "${f}" >"${SHOWN}/${f}"
  if typst compile --root "${SHOWN}" "${SHOWN}/${f}" "${STAGE_ROOT}/$(basename "${f%.typ}").pdf"; then
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

if ! typst-package-check check "${STAGE}"; then
  printf '\nmanifest: typst-package-check reported the above\n' >&2
  exit 1
fi

printf '\nDry-run OK for gribouille:%s\n' "${VERSION}"
