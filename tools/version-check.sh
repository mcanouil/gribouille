#!/usr/bin/env bash
# Holds every written version to the one typst.toml publishes, and refuses a
# version written anywhere else.
#
# tools/bump-version.sh rewrites a fixed set of files: typst.toml,
# CITATION.cff, the CHANGELOG.md heading, the README.md and SKILL.md imports,
# and .claude-plugin/plugin.json. This check reads each of them back, so a bump
# that misses one fails in its own pull request.
#
# Every other file is version-free. The examples import the working tree with
# `#import "/lib.typ"`, and the documentation shows them with the published
# version taken from typst.toml. A hard-coded `@preview/gribouille:x.y.z` outside
# the bump set would go stale at the next release, so it is refused here.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

IMPORT_RE='@preview/gribouille:[0-9]+\.[0-9]+\.[0-9]+'
BUMPED_IMPORTS=(README.md skills/gribouille/SKILL.md)

bad=()
version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
if [[ -z "${version}" ]]; then
  printf 'version-check: typst.toml names no version. Set version = "x.y.z" in typst.toml.\n' >&2
  exit 1
fi

expect() {
  local where="$1" found="$2"
  if [[ "${found}" != "${version}" ]]; then
    bad+=("${where}: has '${found}'; typst.toml has ${version}")
  fi
}

expect "CITATION.cff version" "$(sed -n 's/^version:[[:space:]]*//p' CITATION.cff | head -1)"
expect ".claude-plugin/plugin.json version" \
  "$(sed -nE 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' .claude-plugin/plugin.json | head -1)"
expect "CHANGELOG.md latest release heading" \
  "$(sed -nE 's/^## ([0-9]+\.[0-9]+\.[0-9]+) \(.*/\1/p' CHANGELOG.md | head -1)"

for file in "${BUMPED_IMPORTS[@]}"; do
  found="$(grep -oE "${IMPORT_RE}" "${file}" | cut -d: -f2 | sort -u || true)"
  if [[ -z "${found}" ]]; then
    bad+=("${file}: no @preview/gribouille:${version} import for the release bump to rewrite")
    continue
  fi
  while IFS= read -r one; do
    expect "${file} import" "${one}"
  done <<<"${found}"
done

exclude=()
for file in "${BUMPED_IMPORTS[@]}"; do
  exclude+=(":!${file}")
done
while IFS= read -r hit; do
  bad+=("${hit}: hard-coded version; import \"/lib.typ\" in examples, or write x.y.z in prose")
done < <(git grep -nE "${IMPORT_RE}" -- . "${exclude[@]}" ':!docs/_extensions' || true)

for file in examples/*.typ .github/star-history/star-history.typ; do
  if ! grep -qxF '#import "/lib.typ": *' "${file}"; then
    bad+=("${file}: no '#import \"/lib.typ\": *' line for the documentation to show as the package import")
  fi
done

if [[ ${#bad[@]} -gt 0 ]]; then
  printf '  FAIL  version  %s\n' "${bad[@]}"
  printf 'version:  %d problem(s) against typst.toml %s\n' "${#bad[@]}" "${version}"
  exit 1
fi
printf 'version:  ok (%s)\n' "${version}"
