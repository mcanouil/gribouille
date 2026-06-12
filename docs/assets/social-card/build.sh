#!/usr/bin/env bash
#
# @license MIT
# @copyright 2026 Mickaël Canouil
# @author Mickaël Canouil
#
# Regenerate the Gribouille documentation social card (docs/assets/images/social-card.png).
#
# Steps:
#   1. Render the homepage penguins figure in the light scheme, mirroring how the
#      typst-render filter renders it for the docs: light colour bindings + the
#      contents of docs/_typst-preamble.typ + examples/gribouille.typ (without its
#      own "#import "../lib.typ": *", which the preamble already provides and which
#      would otherwise un-shadow the wrapped theme functions).
#   2. Screenshot social-card.html (1200x630) with headless Chromium via Playwright.
#
# Inputs:  examples/gribouille.typ, docs/_typst-preamble.typ, docs/_brand.yml
#          (light scheme colours), docs/assets/fonts/*.woff2, docs/assets/images/logo.svg
# Output:  docs/assets/social-card/penguins-light.svg (intermediate, git-ignored)
#          docs/assets/images/social-card.png (committed)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

FIGURE_SVG="${SCRIPT_DIR}/penguins-light.svg"
CARD_HTML="${SCRIPT_DIR}/social-card.html"
CARD_PNG="${REPO_ROOT}/docs/assets/images/social-card.png"

# Light-scheme colours, kept in step with docs/_brand.yml (color.palette).
PAPER_LIGHT="#FFFAF0"
INK_LIGHT="#1A1A1A"

TMP_TYP="$(mktemp "${REPO_ROOT}/.tmp-social-card.XXXXXX.typ")"
cleanup() { rm -f "${TMP_TYP}"; }
trap cleanup EXIT

{
	printf '// Auto-assembled by docs/assets/social-card/build.sh; do not edit.\n'
	printf '#let _typst_render_background = rgb("%s")\n' "${PAPER_LIGHT}"
	printf '#let _typst_render_foreground = rgb("%s")\n' "${INK_LIGHT}"
	printf '#set page(fill: _typst_render_background)\n'
	printf '#set text(fill: _typst_render_foreground)\n'
	cat "${REPO_ROOT}/docs/_typst-preamble.typ"
	grep -vxF '#import "../lib.typ": *' "${REPO_ROOT}/examples/gribouille.typ"
} >"${TMP_TYP}"

echo "Rendering penguins figure -> ${FIGURE_SVG}"
quarto typst compile --root "${REPO_ROOT}" "${TMP_TYP}" "${FIGURE_SVG}"

echo "Rendering social card -> ${CARD_PNG}"
npx --yes playwright install chromium >/dev/null
npx --yes playwright screenshot \
	--browser=chromium \
	--viewport-size=1200,630 \
	--wait-for-timeout=2000 \
	"file://${CARD_HTML}" \
	"${CARD_PNG}"

echo "Done."
