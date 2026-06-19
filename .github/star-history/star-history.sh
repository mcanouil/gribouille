#!/usr/bin/env bash
# Fetches a repository's stargazer history and writes a daily-cumulative
# star count as CSV (date,stars) for plotting with Gribouille.
#
# Usage:
#   .github/star-history/star-history.sh [REPO] [OUTPUT]
#     REPO    owner/name of the repository (default: mcanouil/gribouille).
#     OUTPUT  CSV path to write (default: star-history.csv next to this script).
#
# Requires the gh CLI (authenticated) and jq. The stargazers API caps at
# 40,000 stars; beyond that the history would be truncated.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

repo="${1:-mcanouil/gribouille}"
out="${2:-${SCRIPT_DIR}/star-history.csv}"

created="$(gh api "repos/${repo}" --jq '.created_at' | cut -d'T' -f1)"

{
  echo "date,stars"
  echo "${created},0"
  gh api --paginate \
    -H "Accept: application/vnd.github.star+json" \
    "repos/${repo}/stargazers?per_page=100" \
    --jq '.[].starred_at' |
    cut -d'T' -f1 |
    sort |
    uniq -c |
    awk '{ cum += $1; print $2 "," cum }'
} >"${out}"

stars="$(tail -n 1 "${out}" | cut -d',' -f2)"
rows="$(($(wc -l <"${out}") - 1))"
printf 'wrote %s: %s day(s), %s star(s) for %s\n' "${out}" "${rows}" "${stars}" "${repo}" >&2
