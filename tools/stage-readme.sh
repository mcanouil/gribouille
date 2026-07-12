#!/usr/bin/env bash
# Typst Universe does not honour <picture>/<source>; strip the element so
# typst-package-check and the published package do not carry dead HTML.
# Also strip the "Ask DeepWiki" badge, which is repo-only, and GitHub-flavoured
# alert blocks (e.g. "> [!WARNING]") that render as plain blockquotes outside
# GitHub.
# Trim everything from the "## Dependencies" section onward so the published
# README keeps usage and the "## AI assistants" section but omits repo-only
# sections (Dependencies, Contributing, Citation, License).
set -euo pipefail

SRC="${1:?source README path required}"
DEST_DIR="${2:?destination directory required}"
DEST="${DEST_DIR}/README.md"

[[ -f "${SRC}" ]] || { echo "stage-readme: source not found: ${SRC}" >&2; exit 1; }
[[ -d "${DEST_DIR}" ]] || { echo "stage-readme: destination directory not found: ${DEST_DIR}" >&2; exit 1; }

# Refuse if source and destination resolve to the same file; the shell
# redirect below would truncate the source before perl could read it.
src_real="$(cd "$(dirname "${SRC}")" && pwd -P)/$(basename "${SRC}")"
dest_real="$(cd "${DEST_DIR}" && pwd -P)/README.md"
if [[ "${src_real}" == "${dest_real}" ]]; then
  echo "stage-readme: refusing to overwrite source (${src_real})" >&2
  exit 1
fi

perl -0777 -pe '
  s{[ \t]*<picture\b[^>]*>.*?</picture>}{}gs;
  s{^\[!\[Ask DeepWiki\]\([^\n]*\n\n?}{}gm;
  s{^> \[![A-Z]+\][ \t]*\n(?:> [^\n]*\n)*\n?}{}gm;
  s{(^## Quick look\b[^\n]*\n.*?\n)^## Dependencies\b.*\z}{$1}ms;
' "${SRC}" > "${DEST}"
