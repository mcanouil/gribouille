#!/usr/bin/env bash
# Fetches a repository's published releases and writes their dates and tags
# as CSV (date,tag) for overlaying release markers on the Gribouille star chart.
#
# Usage:
#   .github/star-history/release-history.sh [REPO] [OUTPUT]
#     REPO    owner/name of the repository (default: mcanouil/gribouille).
#     OUTPUT  CSV path to write (default: release-history.csv next to this script).
#
# Requires the gh CLI (authenticated) and jq. Drafts and prereleases are
# excluded; rows are sorted by date.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

repo="${1:-mcanouil/gribouille}"
out="${2:-${SCRIPT_DIR}/release-history.csv}"

{
  echo "date,tag"
  gh api --paginate "repos/${repo}/releases?per_page=100" \
    --jq '.[] | select(.draft | not) | select(.prerelease | not) | [(.published_at | split("T")[0]), .tag_name] | @csv' |
    sort
} >"${out}"

rows="$(($(wc -l <"${out}") - 1))"
printf 'wrote %s: %s release(s) for %s\n' "${out}" "${rows}" "${repo}" >&2
