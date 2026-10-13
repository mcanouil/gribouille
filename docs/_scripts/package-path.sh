#!/usr/bin/env bash
#
# Package path for typst-render.
#
# The gallery shows the examples, which import @preview/gribouille as a reader
# does. typst-render resolves that import through docs/.typst-packages, linked
# back to the working tree; _extensions-metadata.yml names it as the package path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "${SCRIPT_DIR}")"
ROOT_DIR="$(dirname "${DOCS_DIR}")"

"${ROOT_DIR}/tools/package-path.sh" "${DOCS_DIR}/.typst-packages" >/dev/null
printf '[pre-render] @preview/gribouille -> working tree (.typst-packages)\n'
