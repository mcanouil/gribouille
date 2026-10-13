#!/usr/bin/env bash
#
# Failed Typst blocks fail the render.
#
# typst-render reports a block that does not compile as a warning, puts an error
# box on the page in place of the figure, and lets the render succeed. A site
# built that way would publish error boxes with a green build, so this runs
# after the render and fails it instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "${SCRIPT_DIR}")"
OUTPUT_DIR="${QUARTO_PROJECT_OUTPUT_DIR:-_site}"
[[ "${OUTPUT_DIR}" = /* ]] || OUTPUT_DIR="${DOCS_DIR}/${OUTPUT_DIR}"

# The pages this render wrote, one per line, or every page when Quarto names none.
pages=()
source_of_pages="QUARTO_PROJECT_OUTPUT_FILES named no .html file"
if [[ -n "${QUARTO_PROJECT_OUTPUT_FILES:-}" ]]; then
  while IFS= read -r page; do
    [[ "${page}" == *.html ]] && pages+=("${page}")
  done <<<"${QUARTO_PROJECT_OUTPUT_FILES}"
else
  source_of_pages="no .html file under ${OUTPUT_DIR}"
  while IFS= read -r page; do
    pages+=("${page}")
  done < <(find "${OUTPUT_DIR}" -name '*.html')
fi

# Reading no page would report success having checked nothing.
if [[ ${#pages[@]} -eq 0 ]]; then
  printf '[post-render] typst-render: no rendered page was read; got 0 pages\n' >&2
  printf '  %s\n' "${source_of_pages}" >&2
  exit 1
fi

failed=()
read_count=0
for page in "${pages[@]}"; do
  [[ "${page}" = /* ]] || page="${DOCS_DIR}/${page}"
  [[ -f "${page}" ]] || continue
  read_count=$((read_count + 1))
  if grep -q 'typst-render-error' "${page}"; then
    failed+=("${page#"${DOCS_DIR}"/}")
  fi
done

# Listed pages that all fail to resolve would also pass having checked nothing.
if [[ ${read_count} -eq 0 ]]; then
  printf '[post-render] typst-render: none of the %d listed page(s) exists under %s\n' "${#pages[@]}" "${DOCS_DIR}" >&2
  exit 1
fi

if [[ ${#failed[@]} -gt 0 ]]; then
  printf '[post-render] typst-render: %d page(s) with a failed block; got:\n' "${#failed[@]}" >&2
  printf '  %s\n' "${failed[@]}" >&2
  printf '  compile the example the page shows with tools/check.sh to see its error\n' >&2
  exit 1
fi
printf '[post-render] typst-render: every block compiled\n'
