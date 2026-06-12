#!/usr/bin/env bash
# Submit gribouille to Typst Universe from a developer machine.
# This is the canonical submitter: opening a fork->upstream PR on typst/packages
# needs a real user identity, so it authenticates with the user's own `gh`
# session (a GitHub App token cannot open that PR). Run it after each release.
#
# @license MIT
# @copyright 2026 Mickaël Canouil
# @author Mickaël Canouil
#
# Usage:
#   .github/scripts/publish-typst-universe.sh [--dry-run] [VERSION]
#
#   VERSION   Release tag to submit (e.g. 0.1.0). Blank uses the latest release.
#   --dry-run Download the release asset, clone and branch locally, but skip
#             push and PR. Still requires the release (and its asset) to exist.
#
# Env:
#   TYPST_PACKAGES_FORK   Fork of typst/packages (owner/repo).
#                         Defaults to "mcanouil/typst-universe-packages".
set -euo pipefail

PKG="gribouille"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

DRY_RUN=0
VERSION=""
for arg in "$@"; do
  case "${arg}" in
    --dry-run) DRY_RUN=1 ;;
    -h | --help)
      awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "unknown option: ${arg}" >&2
      exit 1
      ;;
    *)
      if [[ -n "${VERSION}" ]]; then
        echo "unexpected extra argument: ${arg}" >&2
        exit 1
      fi
      VERSION="${arg}"
      ;;
  esac
done

# --- Preflight ----------------------------------------------------------------
for tool in gh git tar; do
  command -v "${tool}" >/dev/null 2>&1 || {
    echo "required tool not found: ${tool}" >&2
    exit 1
  }
done

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated; run 'gh auth login' first." >&2
  exit 1
fi

FORK="${TYPST_PACKAGES_FORK:-mcanouil/typst-universe-packages}"
FORK_OWNER="${FORK%%/*}"

# --- Resolve version ----------------------------------------------------------
# The payload is the published release asset, so resolve and verify against
# releases rather than local tags.
if [[ -z "${VERSION}" ]]; then
  VERSION="$(gh release view --json tagName --jq '.tagName' 2>/dev/null || true)"
  [[ -n "${VERSION}" ]] || {
    echo "no published release found; pass a VERSION argument." >&2
    exit 1
  }
fi

if ! gh release view "${VERSION}" >/dev/null 2>&1; then
  echo "release not found: ${VERSION}" >&2
  exit 1
fi

BRANCH="${PKG}-${VERSION}"
PKG_PATH="packages/preview/${PKG}"

# --- Temp workspace + cleanup -------------------------------------------------
TMP="$(mktemp -d "${REPO_ROOT}/.typst-universe.XXXXXX")"
trap 'rm -rf "${TMP}"' EXIT
STAGE="${TMP}/stage/${PKG}/${VERSION}"
CLONE="${TMP}/typst-packages"

# --- Stage payload from the published release asset --------------------------
# Pull the exact archive attached to the GitHub release so the Universe payload
# is byte-identical with what users download; no re-staging from source.
ASSET="${PKG}-${VERSION}.tar.gz"
gh release download "${VERSION}" --pattern "${ASSET}" --dir "${TMP}"
mkdir -p "$(dirname "${STAGE}")"
tar -xzf "${TMP}/${ASSET}" -C "${TMP}"
# tools/package.sh names the archive's single root dir gribouille-<version>.
LEAF="${TMP}/${PKG}-${VERSION}"
[[ -d "${LEAF}" ]] || {
  echo "unexpected archive layout: ${ASSET} has no ${PKG}-${VERSION}/ root." >&2
  exit 1
}
mv "${LEAF}" "${STAGE}"
printf 'Staged payload at %s\n' "${STAGE}"

# --- Clone fork of typst/packages --------------------------------------------
# Blobless + sparse: the fork holds 60k+ files; only the gribouille package
# path is ever touched, so avoid checking out the rest.
gh repo clone "${FORK}" "${CLONE}" -- --filter=blob:none --no-checkout --depth 1
# gh repo clone auto-adds `upstream` for forks; only add it when missing.
git -C "${CLONE}" remote get-url upstream >/dev/null 2>&1 \
  || git -C "${CLONE}" remote add upstream https://github.com/typst/packages.git
git -C "${CLONE}" fetch upstream main --depth 1
git -C "${CLONE}" sparse-checkout init --cone
git -C "${CLONE}" sparse-checkout set "${PKG_PATH}"
git -C "${CLONE}" checkout -B "${BRANCH}" upstream/main

# --- Determine new vs update / guard against re-publishing -------------------
if git -C "${CLONE}" cat-file -e "upstream/main:${PKG_PATH}/${VERSION}" 2>/dev/null; then
  echo "${PKG_PATH}/${VERSION} already present upstream (already published)." >&2
  exit 1
fi
if git -C "${CLONE}" cat-file -e "upstream/main:${PKG_PATH}" 2>/dev/null; then
  IS_UPDATE=1
else
  IS_UPDATE=0
fi

# --- Copy payload and commit -------------------------------------------------
DEST="${CLONE}/${PKG_PATH}/${VERSION}"
mkdir -p "$(dirname "${DEST}")"
cp -r "${STAGE}" "${DEST}"
git -C "${CLONE}" add "${PKG_PATH}/${VERSION}"
git -C "${CLONE}" commit -m "Add ${PKG}:${VERSION}" >/dev/null

if [[ "${DRY_RUN}" -eq 1 ]]; then
  printf '\n[dry-run] Would push %s to %s and open a PR against typst/packages.\n' \
    "${BRANCH}" "${FORK}"
  printf '[dry-run] Staged tree:\n'
  git -C "${CLONE}" show --stat --oneline HEAD | sed 's/^/  /'
  exit 0
fi

# --- Push to fork ------------------------------------------------------------
# Force push is intentional: a re-run for the same version replaces the branch.
git -C "${CLONE}" push --force origin "${BRANCH}"

# --- Open or reuse PR against typst/packages ---------------------------------
PR_URL="$(gh pr list \
  --repo typst/packages \
  --head "${FORK_OWNER}:${BRANCH}" \
  --state open \
  --json url --jq '.[0].url // empty')"

if [[ -n "${PR_URL}" ]]; then
  echo "Reusing existing PR: ${PR_URL}"
else
  if [[ "${IS_UPDATE}" -eq 1 ]]; then
    NEW_BOX="[ ]"
    UPDATE_BOX="[x]"
  else
    NEW_BOX="[x]"
    UPDATE_BOX="[ ]"
  fi

  BODY_FILE="${TMP}/pr-body.md"
  {
    printf 'I am submitting\n- %s a new package\n- %s an update for a package\n\n' "${NEW_BOX}" "${UPDATE_BOX}"
    printf 'Description: gribouille — create elegant graphics with the Grammar of Graphics for Typst, inspired by ggplot2 and plotnine. Declarative API: aesthetic mappings, geoms, stats, scales, coordinates, facets, themes.\n\n'
    printf -- '- Upstream repository: https://github.com/mcanouil/gribouille\n'
    printf -- '- Release: https://github.com/mcanouil/gribouille/releases/tag/%s\n' "${VERSION}"
    printf -- '- Homepage: https://m.canouil.dev/gribouille\n'

    # shellcheck disable=SC2016 # backticks are literal markdown, not expansions
    if [[ "${IS_UPDATE}" -eq 0 ]]; then
      printf '\nI have read and followed the submission guidelines and, in particular, I\n'
      printf -- '- [x] selected a name that isn'\''t the most obvious or canonical name for what the package does\n'
      printf -- '- [x] added a `typst.toml` file with all required keys\n'
      printf -- '- [x] added a `README.md` with documentation for my package\n'
      printf -- '- [x] have chosen a license and added a `LICENSE` file or linked one in my `README.md`\n'
      printf -- '- [x] tested my package locally on my system and it worked\n'
      printf -- '- [x] excluded PDFs or README images, if any, but not the LICENSE\n'
    fi
  } >"${BODY_FILE}"

  PR_URL="$(gh pr create \
    --repo typst/packages \
    --base main \
    --head "${FORK_OWNER}:${BRANCH}" \
    --title "${PKG}:${VERSION}" \
    --body-file "${BODY_FILE}")"
fi

# --- Summary -----------------------------------------------------------------
printf '\nTypst Universe submission\n'
printf -- '- Package: %s:%s\n' "${PKG}" "${VERSION}"
printf -- '- Fork branch: %s:%s\n' "${FORK}" "${BRANCH}"
printf -- '- PR: %s\n' "${PR_URL}"
